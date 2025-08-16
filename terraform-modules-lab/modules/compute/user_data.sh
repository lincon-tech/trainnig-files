#!/bin/bash

# Update system
yum update -y

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Git
yum install -y git

# Create application directory
mkdir -p /opt/taskmaster
cd /opt/taskmaster

# Create a simple Node.js application
cat > app.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

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

app.listen(port, () => {
    console.log(`TaskMaster app listening at http://localhost:${port}`);
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
User=ec2-user
WorkingDirectory=/opt/taskmaster
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Change ownership
chown -R ec2-user:ec2-user /opt/taskmaster

# Enable and start the service
systemctl daemon-reload
systemctl enable taskmaster
systemctl start taskmaster

# Install CloudWatch agent (optional)
yum install -y amazon-cloudwatch-agent