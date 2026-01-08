# API Configuration for Minecraft Church Verification System
# Update these values with your actual API URL

api_config:
  type: data
  data:
    # Your public API URL (e.g., http://your-ip:3000 or https://your-domain.com)
    # For local development with public exposure, use a service like ngrok or your public IP
    # REQUIRED: Set this to your actual API URL
    api_url: "YOUR_API_URL"
    
    # Your API secret from .env file (API_SECRET)
    # OPTIONAL: Leave as "YOUR_API_SECRET" or empty string to disable authentication
    # Only set this if you've configured API_SECRET in your .env file
    api_secret: "YOUR_API_SECRET"
    
    # Your Wix form URL
    # REQUIRED: Set this to your actual Wix form URL
    wix_form_url: "YOUR_WIX_FORM_URL"
