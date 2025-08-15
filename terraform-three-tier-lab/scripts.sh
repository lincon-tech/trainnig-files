#!/bin/bash
# yum update -y
# yum install -y httpd
# cat <<EOF > /var/www/html/index.html
# <html>
# <head>
# <title>Movie Ticket Booking Platform</title>
# </head>
# <body style="font-family: Arial; text-align: center;">
# <h1>Welcome to the Movie Ticket Booking Platform</h1>
# <p>Deployed via Terraform & Auto Scaling</p>
# <hr>
# <p>Frontend Server IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
# </body>
# </html>
# EOF
# systemctl start httpd
# systemctl enable httpd


# Frontend instance setup script
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple index page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>ShopNow - Three-Tier Architecture</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { background: #d4edda; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 ShopNow Web Application</h1>
        <div class="status">
            <h2>✅ Frontend Tier Active</h2>
            <p>Server: $(hostname)</p>
            <p>Deployed: $(date)</p>
            <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
        </div>
        <h3>Architecture Status:</h3>
        <ul>
            <li>✅ Load Balancer: Distributing traffic</li>
            <li>✅ Auto Scaling: Monitoring demand</li>
            <li>✅ Multi-AZ: High availability enabled</li>
        </ul>
    </div>
</body>
</html>
EOF

# Create health check endpoint
echo "OK" > /var/www/html/health

# Start and enable httpd
systemctl restart httpd
