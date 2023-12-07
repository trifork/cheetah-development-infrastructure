FROM alpine:latest

# Install necessary packages (sed in this case)
RUN apk add --no-cache sed

# Set the working directory inside the container
WORKDIR /

# Copy the script and other necessary files
COPY ./keycloak_env_var_substitution.sh ./local-development.json ./

# Make the script executable
RUN chmod +x keycloak_env_var_substitution.sh

# Define the entry point for the container
CMD ["./keycloak_env_var_substitution.sh"]