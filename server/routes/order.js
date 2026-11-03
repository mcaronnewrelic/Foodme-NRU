const { Router } = require("express");
const { randomUUID } = require("node:crypto");
const bodyParser = require("body-parser");

// Utility function to generate consistent user IDs for New Relic tracking
function generateUserID(customerData) {
  if (!customerData) return null;

  // The customer's name is their demoCode in this app (sample data only;
  // email is never collected, so it can never be an identifier here).
  if (customerData.name) {
    return `user_${customerData.name.toLowerCase().replace(/[^a-z0-9]/g, "_")}`;
  }

  // Fallback to phone if available
  if (customerData.phone) {
    return `user_phone_${customerData.phone.replace(/[^0-9]/g, "")}`;
  }

  return null;
}

module.exports = function createOrderRouter({
  storage,
  dbService,
  useDatabase,
  logger,
  newrelic,
  demoFailures,
  demoInvestigations,
}) {
  const router = Router();
  const jsonParser = bodyParser.json();

  function setNewRelicUserID(customerData, context = "") {
    const userID = generateUserID(customerData);
    if (userID) {
      try {
        newrelic.setUserID(userID);
        logger.debug({ userID, context }, "New Relic user ID set");
        return userID;
      } catch (error) {
        logger.warn({ err: error, context }, "Failed to set New Relic user ID");
      }
    }
    return null;
  }

  router.post("/order", jsonParser, async function (req, res, next) {
    const startTime = Date.now();
    const order = req.body;

    const restaurantId = order?.restaurant_id || order?.restaurant?.id;
    if (
      !restaurantId ||
      !Array.isArray(order?.items) ||
      order.items.length === 0 ||
      order.items.some((item) => !item)
    ) {
      return res.status(400).json({
        error: "A restaurant and at least one menu item are required",
      });
    }

    let restaurant;
    try {
      restaurant = useDatabase
        ? await dbService.getRestaurantById(restaurantId)
        : storage.getById(restaurantId);
      if (!restaurant) {
        return res.status(400).json({ error: "Restaurant not found" });
      }
      const invalidItem = order.items.some((item) => {
        const itemRestaurantId = item.restaurant_id || item.restaurant?.id;
        const menuItemId = item.menu_item_id || item.id;
        return (
          (itemRestaurantId != null &&
            String(itemRestaurantId) !== String(restaurantId)) ||
          !restaurant.menuItems.some((menuItem) =>
            menuItemId != null
              ? String(menuItem.id) === String(menuItemId)
              : typeof (item.item_name || item.name) === "string" &&
                menuItem.name.toLowerCase() ===
                  (item.item_name || item.name).toLowerCase(),
          )
        );
      });
      if (invalidItem) {
        return res.status(400).json({
          error: "All order items must belong to the selected restaurant",
        });
      }
    } catch (error) {
      return next(error);
    }

    logger.info(
      {
        requestId: req.requestId,
        endpoint: "POST /api/order",
        customerName: order.deliverTo?.name || order.customer?.name,
        restaurantId: order.restaurant?.id,
        restaurantName: order.restaurant?.name,
        itemCount: order.items?.length || 0,
      },
      "Processing order checkout",
    );

    // Log the full order for debugging (can be removed in production)
    logger.debug({ requestId: req.requestId, order }, "Order details");

    try {
      var itemCount = 0;
      var orderTotal = 0;
      order.items.forEach(function (item) {
        itemCount += item.qty;
        orderTotal += Math.round(item.price * 100) * item.qty;
      });
      orderTotal /= 100;

      logger.info(
        {
          requestId: req.requestId,
          orderMetrics: {
            totalItems: itemCount,
            totalAmount: orderTotal,
            uniqueMenuItems: order.items.length,
          },
        },
        "Order metrics calculated",
      );

      // Set New Relic user ID for transaction tracking
      const customerData = order.deliverTo || order.customer;
      const userID = setNewRelicUserID(customerData, "order_creation");

      logger.info(
        {
          requestId: req.requestId,
          userID: userID,
          customerName: customerData?.name,
        },
        "User ID set for order creation transaction",
      );

      const demoCode = /^(OU|SIM)-[A-Z0-9]{4}$/.test(order.demoCode || "")
        ? order.demoCode
        : null;

      // Add New Relic monitoring
      newrelic.addCustomAttributes({
        ...(demoCode ? { demoCode } : {}),
        customer: order.deliverTo?.name || order.customer?.name || "Unknown",
        userID: userID || "anonymous",
        restaurant: restaurant.name,
        itemCount: itemCount,
        orderTotal: orderTotal,
        requestId: req.requestId,
      });

      // Planned failures for the "find the failed order in New Relic" exercise; each is off unless its variable is set.
      // They run after the attributes above, so the failed transaction still says who ordered what, and before the
      // Item events and metrics below, so a failed order isn't counted as a sale.
      const { nameToSlug } = require("../url-utils");
      const failing = demoFailures.getFailing();
      const failingItem = failing.orderItem
        ? order.items.find(
            (item) => nameToSlug(item.name) === failing.orderItem,
          )
        : undefined;
      if (failingItem) {
        newrelic.addCustomAttributes({ failedItem: failingItem.name });
        throw new Error(
          `Inventory check failed for "${failingItem.name}": stock count is -2`,
        );
      }
      if (
        failing.orderRestaurant &&
        nameToSlug(restaurant.name) === failing.orderRestaurant
      ) {
        throw new Error(
          `Kitchen at "${restaurant.name}" is not accepting orders: ticket printer offline`,
        );
      }

      // Actually create the order in the database if using database
      let orderId;

      if (useDatabase && dbService) {
        try {
          const dbStartTime = Date.now();
          // I2 arm (spec section 11): an armed slow query inside the
          // order's database work, so the transaction's time sits in a
          // datastore span for students to find. See demo-investigations.js.
          const slowSeconds = demoInvestigations.slowOrderSeconds();
          if (slowSeconds > 0) {
            await dbService.sleepSeconds(slowSeconds);
          }
          const result = await dbService.createOrder(order);
          const dbDuration = Date.now() - dbStartTime;

          orderId = result.orderId;

          logger.info(
            {
              requestId: req.requestId,
              operation: "database.createOrder",
              orderId: orderId,
              orderNumber: result.orderNumber,
              customerId: result.customerId,
              duration: dbDuration,
            },
            "Order created successfully in database",
          );
        } catch (dbError) {
          logger.error(
            {
              requestId: req.requestId,
              operation: "database.createOrder",
              err: dbError,
              orderData: {
                customerName: order.deliverTo?.name || order.customer?.name,
                restaurantId: order.restaurant?.id,
                itemCount,
                orderTotal,
              },
            },
            "Database order creation failed",
          );

          throw dbError;
        }
      } else {
        orderId = randomUUID();
        logger.info(
          {
            requestId: req.requestId,
            operation: "memory.createOrder",
            orderId,
          },
          "Order processed in memory mode",
        );
      }

      orderId = String(orderId);
      newrelic.addCustomAttributes({ orderId });
      for (const item of order.items) {
        newrelic.recordCustomEvent("ItemsOrdered", {
          ...(demoCode ? { demoCode } : {}),
          orderId,
          itemName: item.name,
          itemCount: item.qty,
          unitPrice: item.price,
          itemTotal: (Math.round(item.price * 100) * item.qty) / 100,
        });
      }
      newrelic.recordMetric("total", orderTotal);
      newrelic.recordMetric(`${nameToSlug(restaurant.name)}/total`, orderTotal);

      const totalDuration = Date.now() - startTime;
      logger.info(
        {
          requestId: req.requestId,
          endpoint: "POST /api/order",
          statusCode: 201,
          orderId,
          duration: totalDuration,
          orderTotal,
        },
        "Order processing completed successfully",
      );

      return res
        .status(201)
        .send({ orderId: orderId, requestId: req.requestId });
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(
        {
          requestId: req.requestId,
          endpoint: "POST /api/order",
          err: error,
          duration,
          orderData: {
            customerName: order.deliverTo?.name || order.customer?.name,
            restaurantId: order.restaurant?.id,
            itemCount: order.items?.length,
          },
        },
        "Error processing order",
      );
      return next(error);
    }
  });

  // Orders API endpoints
  router.get("/orders/customer/phone/:phone", async function (req, res, next) {
    const startTime = Date.now();
    const customerPhone = req.params.phone;

    // Set New Relic user ID for transaction tracking
    const userID = setNewRelicUserID(
      { phone: customerPhone },
      "orders_by_phone",
    );

    logger.info(
      {
        requestId: req.requestId,
        endpoint: "GET /api/orders/customer/phone/:phone",
        customerPhone,
        userID,
        useDatabase,
      },
      "Fetching orders by customer phone",
    );

    // Add New Relic custom attributes for this transaction
    newrelic.addCustomAttributes({
      customerPhone: customerPhone,
      userID: userID || "anonymous",
      requestId: req.requestId,
      operation: "get_orders_by_phone",
    });

    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const orders = await dbService.getOrdersByCustomerPhone(customerPhone);
        const dbDuration = Date.now() - dbStartTime;

        logger.info(
          {
            requestId: req.requestId,
            operation: "database.getOrdersByCustomerPhone",
            customerPhone,
            orderCount: orders.length,
            duration: dbDuration,
          },
          "Orders retrieved from database by phone",
        );

        const totalDuration = Date.now() - startTime;
        logger.info(
          {
            requestId: req.requestId,
            endpoint: "GET /api/orders/customer/phone/:phone",
            statusCode: 200,
            customerPhone,
            orderCount: orders.length,
            duration: totalDuration,
          },
          "Successfully fetched customer orders by phone",
        );

        return res.status(200).send(orders);
      } else {
        logger.info(
          {
            requestId: req.requestId,
            operation: "memory.getOrders",
            customerPhone,
          },
          "Using memory mode - returning empty orders",
        );

        return res.status(200).send([]);
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(
        {
          requestId: req.requestId,
          endpoint: "GET /api/orders/customer/phone/:phone",
          customerPhone,
          err: error,
          duration,
        },
        "Failed to fetch orders by customer phone",
      );
      res.status(500).send({ error: "Failed to fetch orders" });
    }
  });

  router.get("/orders/:id", async function (req, res, next) {
    const startTime = Date.now();
    const orderId = req.params.id;

    logger.info(
      {
        requestId: req.requestId,
        endpoint: "GET /api/orders/:id",
        orderId,
        useDatabase,
      },
      "Fetching order by ID",
    );

    // Add New Relic custom attributes for this transaction
    newrelic.addCustomAttributes({
      orderId: orderId,
      requestId: req.requestId,
      operation: "get_order_by_id",
    });

    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const order = await dbService.getOrderById(orderId);
        const dbDuration = Date.now() - dbStartTime;

        if (order) {
          // Set user ID if we have customer information in the order
          if (order.customer_phone || order.customer_name) {
            const userID = setNewRelicUserID(
              {
                phone: order.customer_phone,
                name: order.customer_name,
              },
              "order_by_id",
            );

            // Update New Relic attributes with user information
            newrelic.addCustomAttributes({
              customerPhone: order.customer_phone,
              userID: userID || "anonymous",
            });
          }

          logger.info(
            {
              requestId: req.requestId,
              operation: "database.getOrderById",
              orderId,
              duration: dbDuration,
              hasCustomerInfo: !!(order.customer_phone || order.customer_name),
            },
            "Order retrieved from database",
          );

          const totalDuration = Date.now() - startTime;
          logger.info(
            {
              requestId: req.requestId,
              endpoint: "GET /api/orders/:id",
              statusCode: 200,
              orderId,
              duration: totalDuration,
            },
            "Successfully fetched order",
          );

          return res.status(200).send(order);
        }

        logger.warn(
          {
            requestId: req.requestId,
            orderId,
            duration: Date.now() - startTime,
          },
          "Order not found",
        );

        return res
          .status(404)
          .send({ error: 'No order with id "' + orderId + '"!' });
      } else {
        logger.info(
          {
            requestId: req.requestId,
            operation: "memory.getOrder",
            orderId,
          },
          "Using memory mode - returning 404",
        );

        return res.status(404).send({ error: "Order not found" });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(
        {
          requestId: req.requestId,
          endpoint: "GET /api/orders/:id",
          orderId,
          err: error,
          duration,
        },
        "Failed to fetch order by ID",
      );
      res.status(500).send({ error: "Failed to fetch order" });
    }
  });

  return router;
};
