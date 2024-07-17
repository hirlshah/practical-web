# Use a lightweight node image
FROM node:14-alpine

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose application on port 3000
EXPOSE 3000

# Command to run the application
CMD ["node", "app.js"]
