from flask import Flask, render_template, request, redirect, url_for, session
import os
import uuid
from datetime import datetime

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')

# In-memory storage for orders (in production, use a database)
orders = {}

# Pizza menu
MENU = {
    'margherita': {'name': 'Margherita', 'price': 12.99},
    'pepperoni': {'name': 'Pepperoni', 'price': 14.99},
    'supreme': {'name': 'Supreme', 'price': 17.99},
    'veggie': {'name': 'Veggie Deluxe', 'price': 15.99},
    'hawaiian': {'name': 'Hawaiian', 'price': 16.99}
}

SIZES = {
    'small': {'name': 'Small (10")', 'multiplier': 0.8},
    'medium': {'name': 'Medium (12")', 'multiplier': 1.0},
    'large': {'name': 'Large (14")', 'multiplier': 1.3}
}

@app.route('/')
def index():
    return render_template('index.html', menu=MENU, sizes=SIZES)

@app.route('/order', methods=['POST'])
def order():
    pizza_type = request.form.get('pizza')
    size = request.form.get('size')
    customer_name = request.form.get('customer_name')
    customer_phone = request.form.get('customer_phone')
    
    if not all([pizza_type, size, customer_name, customer_phone]):
        return redirect(url_for('index'))
    
    # Calculate price
    base_price = MENU[pizza_type]['price']
    size_multiplier = SIZES[size]['multiplier']
    total_price = round(base_price * size_multiplier, 2)
    
    # Create order
    order_id = str(uuid.uuid4())[:8]
    order_data = {
        'id': order_id,
        'pizza': MENU[pizza_type]['name'],
        'size': SIZES[size]['name'],
        'customer_name': customer_name,
        'customer_phone': customer_phone,
        'price': total_price,
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'status': 'confirmed'
    }
    
    orders[order_id] = order_data
    session['last_order'] = order_id
    
    return render_template('confirmation.html', order=order_data)

@app.route('/orders')
def view_orders():
    return render_template('order.html', orders=orders)

@app.route('/health')
def health_check():
    return {'status': 'healthy', 'orders_count': len(orders)}, 200

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 3000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)