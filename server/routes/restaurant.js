const { Router } = require("express");
const RestaurantRecord = require("../model").Restaurant;

var removeMenuItems = function (restaurant) {
  var clone = {};

  Object.getOwnPropertyNames(restaurant).forEach(function (key) {
    if (key !== "menuItems") {
      clone[key] = restaurant[key];
    }
  });

  // Add image URL based on restaurant original ID
  if (restaurant.original_id) {
    clone.image = `/assets/img/restaurants/${restaurant.original_id}.jpg`;
  } else if (restaurant.id) {
    // Fallback to regular id for non-database sources
    clone.image = `/assets/img/restaurants/${restaurant.id}.jpg`;
  }

  return clone;
};

module.exports = function createRestaurantRouter({
  storage,
  dbService,
  useDatabase,
  logger,
  newrelic,
  demoFailures,
  demoInvestigations,
}) {
  const router = Router();

  // I5 arm (spec section 11): while "The 502 didn't come from the app" is
  // armed, every second GET under /api/restaurant has its socket destroyed
  // before any route runs - nginx, the real proxy in front, experiences an
  // upstream that dies mid-answer and mints a genuine 502 (its error log:
  // "upstream prematurely closed connection"). The app produces no error
  // and no response; that silence in APM is the investigation's evidence.
  router.use((req, res, next) => {
    if (req.method === "GET" && demoInvestigations.shouldDestroySocket()) {
      logger.info(
        { url: req.originalUrl, ip: req.ip },
        "I5 arm: destroying socket to simulate a dying upstream",
      );
      req.socket.destroy();
      return;
    }
    next();
  });

  // API
  router.get("/", async function (req, res, next) {
    const startTime = Date.now();
    logger.info(
      {
        requestId: req.requestId,
        endpoint: "GET /api/restaurant",
        useDatabase,
      },
      "Fetching all restaurants",
    );

    try {
      let restaurants;
      if (useDatabase) {
        const dbStartTime = Date.now();
        restaurants = await dbService.getAllRestaurants();
        const dbDuration = Date.now() - dbStartTime;

        logger.info(
          {
            requestId: req.requestId,
            operation: "database.getAllRestaurants",
            duration: dbDuration,
            resultCount: restaurants.length,
          },
          "Database query completed",
        );

        res.status(200).send(restaurants.map(removeMenuItems));
      } else {
        restaurants = storage.getAll();
        logger.info(
          {
            requestId: req.requestId,
            operation: "storage.getAll",
            resultCount: restaurants.length,
          },
          "In-memory storage query completed",
        );

        res.status(200).send(restaurants.map(removeMenuItems));
      }

      const totalDuration = Date.now() - startTime;
      logger.info(
        {
          requestId: req.requestId,
          endpoint: "GET /api/restaurant",
          statusCode: 200,
          resultCount: restaurants.length,
          duration: totalDuration,
        },
        "Successfully fetched restaurants",
      );
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(
        {
          requestId: req.requestId,
          endpoint: "GET /api/restaurant",
          err: error,
          duration,
        },
        "Failed to fetch restaurants from API",
      );
      res.status(500).send({ error: "Failed to fetch restaurants" });
    }
  });

  router.post("/", async function (req, res, next) {
    const startTime = Date.now();
    logger.info(
      {
        requestId: req.requestId,
        endpoint: "POST /api/restaurant",
        restaurantName: req.body?.name,
        hasMenuItems: !!(req.body?.menuItems && req.body.menuItems.length > 0),
        useDatabase,
      },
      "Adding new restaurant",
    );

    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const restaurant = await dbService.addRestaurant(req.body);
        const dbDuration = Date.now() - dbStartTime;

        logger.info(
          {
            requestId: req.requestId,
            operation: "database.addRestaurant",
            restaurantId: restaurant.id,
            duration: dbDuration,
          },
          "Restaurant added to database",
        );

        const totalDuration = Date.now() - startTime;
        logger.info(
          {
            requestId: req.requestId,
            endpoint: "POST /api/restaurant",
            statusCode: 201,
            restaurantId: restaurant.id,
            duration: totalDuration,
          },
          "Successfully added restaurant",
        );

        return res.status(201).send(restaurant);
      } else {
        var restaurant = new RestaurantRecord(req.body);
        var errors = [];

        if (restaurant.validate(errors)) {
          storage.add(restaurant);

          logger.info(
            {
              requestId: req.requestId,
              operation: "storage.add",
              restaurantId: restaurant.id,
            },
            "Restaurant added to storage",
          );

          const totalDuration = Date.now() - startTime;
          logger.info(
            {
              requestId: req.requestId,
              endpoint: "POST /api/restaurant",
              statusCode: 201,
              restaurantId: restaurant.id,
              duration: totalDuration,
            },
            "Successfully added restaurant",
          );

          return res.status(201).send(restaurant);
        }

        logger.warn(
          {
            requestId: req.requestId,
            endpoint: "POST /api/restaurant",
            errors: errors,
          },
          "Restaurant validation failed",
        );

        return res.status(400).send({ error: errors });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(
        {
          requestId: req.requestId,
          endpoint: "POST /api/restaurant",
          err: error,
          duration,
        },
        "Failed to add restaurant",
      );
      res.status(500).send({ error: "Failed to add restaurant" });
    }
  });

  router.get("/:id", async function (req, res, next) {
    const startTime = Date.now();
    const restaurantId = req.params.id;

    logger.info(
      {
        requestId: req.requestId,
        endpoint: "GET /api/restaurant/:id",
        restaurantId,
        useDatabase,
      },
      "Fetching restaurant by ID",
    );

    try {
      if (useDatabase) {
        const dbStartTime = Date.now();
        const restaurant = await dbService.getRestaurantById(restaurantId);
        const dbDuration = Date.now() - dbStartTime;

        if (restaurant) {
          logger.info(
            {
              requestId: req.requestId,
              operation: "database.getRestaurantById",
              restaurantId,
              restaurantName: restaurant.name,
              duration: dbDuration,
            },
            "Restaurant found in database",
          );

          const totalDuration = Date.now() - startTime;
          logger.info(
            {
              requestId: req.requestId,
              endpoint: "GET /api/restaurant/:id",
              statusCode: 200,
              restaurantId,
              duration: totalDuration,
            },
            "Successfully fetched restaurant",
          );

          return res.status(200).send(restaurant);
        }

        logger.warn(
          {
            requestId: req.requestId,
            operation: "database.getRestaurantById",
            restaurantId,
            duration: dbDuration,
          },
          "Restaurant not found in database",
        );

        return res
          .status(404)
          .send({ error: 'No restaurant with id "' + restaurantId + '"!' });
      } else {
        var restaurant = storage.getById(restaurantId);
        if (restaurant) {
          logger.info(
            {
              requestId: req.requestId,
              operation: "storage.getById",
              restaurantId,
              restaurantName: restaurant.name,
            },
            "Restaurant found in storage",
          );

          const totalDuration = Date.now() - startTime;
          logger.info(
            {
              requestId: req.requestId,
              endpoint: "GET /api/restaurant/:id",
              statusCode: 200,
              restaurantId,
              duration: totalDuration,
            },
            "Successfully fetched restaurant",
          );

          return res.status(200).send(restaurant);
        }

        logger.warn(
          {
            requestId: req.requestId,
            operation: "storage.getById",
            restaurantId,
          },
          "Restaurant not found in storage",
        );

        return res
          .status(404)
          .send({ error: 'No restaurant with id "' + restaurantId + '"!' });
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(
        {
          requestId: req.requestId,
          endpoint: "GET /api/restaurant/:id",
          restaurantId,
          err: error,
          duration,
        },
        "Failed to fetch restaurant by ID",
      );
      res.status(500).send({ error: "Failed to fetch restaurant" });
    }
  });

  // New endpoint for getting restaurant by name slug
  router.get("/by-name/:name", async function (req, res, next) {
    newrelic.addCustomAttributes({ restaurantSlug: req.params.name });
    try {
      // Planned failure for the "find the error in New Relic" exercise;
      // armed dynamically (env, instructor override, or weekly rotation)
      if (demoFailures.getFailing().restaurant === req.params.name) {
        throw new Error(
          `Menu data for "${req.params.name}" is corrupted: menu_items.category is null for 3 rows`,
        );
      }
      if (useDatabase) {
        const restaurant = await dbService.getRestaurantByName(req.params.name);
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({
          error: 'No restaurant with name "' + req.params.name + '"!',
        });
      } else {
        // For non-database mode, we need to search by name in storage
        const { nameToSlug } = require("../url-utils");
        const restaurant = storage
          .getAll()
          .find((r) => nameToSlug(r.name) === req.params.name);

        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res.status(404).send({
          error: 'No restaurant with name "' + req.params.name + '"!',
        });
      }
    } catch (error) {
      logger.error(
        { err: error, restaurantName: req.params.name },
        "Failed to fetch restaurant by name",
      );
      next(error);
    }
  });

  router.put("/:id", async function (req, res, next) {
    try {
      if (useDatabase) {
        const restaurant = await dbService.updateRestaurant(
          req.params.id,
          req.body,
        );
        if (restaurant) {
          return res.status(200).send(restaurant);
        }
        return res
          .status(404)
          .send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      } else {
        var restaurant = storage.getById(req.params.id);
        var errors = [];

        if (restaurant) {
          restaurant.update(req.body);
          return res.status(200).send(restaurant);
        }

        restaurant = new RestaurantRecord(req.body);
        if (restaurant.validate(errors)) {
          storage.add(restaurant);
          return res.status(201).send(restaurant);
        }

        return res.status(400).send({ error: errors });
      }
    } catch (error) {
      logger.error(
        { err: error, restaurantId: req.params.id },
        "Failed to update restaurant",
      );
      res.status(500).send({ error: "Failed to update restaurant" });
    }
  });

  router.delete("/:id", async function (req, res, next) {
    try {
      if (useDatabase) {
        const success = await dbService.deleteRestaurant(req.params.id);
        if (success) {
          return res.status(204).send(null);
        }
        return res
          .status(404)
          .send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      } else {
        if (storage.deleteById(req.params.id)) {
          return res.status(204).send(null);
        }
        return res
          .status(404)
          .send({ error: 'No restaurant with id "' + req.params.id + '"!' });
      }
    } catch (error) {
      logger.error(
        { err: error, restaurantId: req.params.id },
        "Failed to delete restaurant",
      );
      res.status(500).send({ error: "Failed to delete restaurant" });
    }

    return res
      .status(400)
      .send({ error: 'No restaurant with id "' + req.params.id + '"!' });
  });

  return router;
};
