FROM nginx:1.25-alpine

# Copy the nginx configuration
COPY nginx-config/foodme.dev.conf /etc/nginx/conf.d/default.conf

# Remove the default nginx configuration
RUN rm -f /etc/nginx/conf.d/default.conf.bak

# Create log directory
RUN mkdir -p /var/log/nginx

# Expose port 80
EXPOSE 80

# Use the default nginx entrypoint
CMD ["nginx", "-g", "daemon off;"]
