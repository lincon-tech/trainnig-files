#!/bin/bash

# Update system
sudo apt update -y
sudo apt upgrade -y

# Install curl and other prerequisites
sudo apt install -y curl git build-essential

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
sudo apt install -y npm

# Verify Node.js and npm installation
node -v
npm -v

# Create application directory
sudo mkdir -p /opt/taskmaster
sudo chown ubuntu:ubuntu /opt/taskmaster
cd /opt/taskmaster

# Create a simple Node.js application
cat > app.js << 'EOF'
const express = require('express');
const app = express();
const app_port = 3000;

// Serve static files
app.use(express.static('public'));

// Basic routes
app.get('/', (req, res) => {
    res.send(`
        <html>
            <head>
                <title>TaskMaster - ${project_name}</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; }
                    .header { background: #007bff; color: white; padding: 20px; border-radius: 5px; }
                    .content { margin: 20px 0; }
                    .instance-info { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>🚀 TaskMaster Application</h1>
                    <p>Environment: ${environment}</p>
                </div>
                <div class="content">
                    <h2>Welcome to TaskMaster!</h2>
                    <p>This is a simple task management application deployed using Terraform modules.</p>
                    <div class="instance-info">
                        <h3>Instance Information:</h3>
                        <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                        <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                        <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
                        <p><strong>Local IP:</strong> $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)</p>
                    </div>
                    <h3>Features:</h3>
                    <ul>
                        <li>✅ Deployed with Terraform</li>
                        <li>✅ Load Balanced</li>
                        <li>✅ High Availability</li>
                        <li>✅ Automated Deployment</li>
                    </ul>
                </div>
            </body>
        </html>
    `);
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: '${environment}',
        project: '${project_name}'
    });
});

app.listen(app_port, () => {
    console.log(`TaskMaster app listening at http://0.0.0.0:${app_port}`);
});
EOF

# Create package.json
cat > package.json << 'EOF'
{
    "name": "taskmaster",
    "version": "1.0.0",
    "description": "Simple task management application",
    "main": "app.js",
    "scripts": {
        "start": "node app.js",
        "dev": "nodemon app.js"
    },
    "dependencies": {
        "express": "^4.18.2"
    },
    "keywords": ["task", "management", "terraform"],
    "author": "TechStart Solutions"
}
EOF

# Install dependencies
npm install

# Create systemd service
cat > /etc/systemd/system/taskmaster.service << 'EOF'
[Unit]
Description=TaskMaster Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/taskmaster
ExecStart=/usr/bin/node /opt/taskmaster/app.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Change ownership
sudo chown -R ubuntu:ubuntu /opt/taskmaster

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable taskmaster
sudo systemctl start taskmaster

# Optional: Install CloudWatch agent
sudo apt install -y amazon-cloudwatch-agent
