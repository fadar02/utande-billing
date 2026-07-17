import os
from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required
from werkzeug.utils import secure_filename

from app import admin_required
from models import db, Product, Order, ProductCategory, OrderStatus

merchandise_bp = Blueprint('merchandise', __name__, url_prefix='/admin/merchandise')


def save_upload(file, subfolder):
    if not file or file.filename == '':
        return None
    filename = secure_filename(file.filename)
    filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{filename}"
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, filename))
    return filename


@merchandise_bp.route('/')
@admin_required
def list_products():
    products = Product.query.order_by(Product.created_at.desc()).all()
    return render_template('admin/merchandise/list.html', products=products)


@merchandise_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_product():
    if request.method == 'POST':
        image = save_upload(request.files.get('image'), 'products')
        product = Product(
            name=request.form['name'],
            description=request.form.get('description'),
            category=ProductCategory(request.form['category']),
            price=float(request.form['price']),
            stock_quantity=int(request.form.get('stock_quantity', 0)),
            image=image,
            is_active='is_active' in request.form
        )
        db.session.add(product)
        db.session.commit()
        flash('Product added successfully.', 'success')
        return redirect(url_for('merchandise.list_products'))
    return render_template('admin/merchandise/add.html')


@merchandise_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_product(id):
    product = Product.query.get_or_404(id)
    if request.method == 'POST':
        image = save_upload(request.files.get('image'), 'products')
        if image:
            old_image = os.path.join(current_app.config['UPLOAD_FOLDER'], 'products', product.image) if product.image else None
            if old_image and os.path.exists(old_image):
                os.remove(old_image)
            product.image = image
        product.name = request.form['name']
        product.description = request.form.get('description')
        product.category = ProductCategory(request.form['category'])
        product.price = float(request.form['price'])
        product.stock_quantity = int(request.form.get('stock_quantity', 0))
        product.is_active = 'is_active' in request.form
        db.session.commit()
        flash('Product updated successfully.', 'success')
        return redirect(url_for('merchandise.list_products'))
    return render_template('admin/merchandise/edit.html', product=product)


@merchandise_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_product(id):
    product = Product.query.get_or_404(id)
    if product.image:
        image_path = os.path.join(current_app.config['UPLOAD_FOLDER'], 'products', product.image)
        if os.path.exists(image_path):
            os.remove(image_path)
    db.session.delete(product)
    db.session.commit()
    flash('Product deleted successfully.', 'success')
    return redirect(url_for('merchandise.list_products'))


@merchandise_bp.route('/orders')
@admin_required
def list_orders():
    orders = Order.query.order_by(Order.created_at.desc()).all()
    return render_template('admin/merchandise/orders.html', orders=orders)


@merchandise_bp.route('/orders/<int:id>/update-status', methods=['POST'])
@admin_required
def update_order_status(id):
    order = Order.query.get_or_404(id)
    order.status = OrderStatus(request.form['status'])
    db.session.commit()
    flash('Order status updated successfully.', 'success')
    return redirect(url_for('merchandise.list_orders'))
