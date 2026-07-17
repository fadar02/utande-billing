from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required

from app import admin_required
from models import db, Transaction, TransactionType

transactions_bp = Blueprint('transactions', __name__, url_prefix='/admin/transactions')


@transactions_bp.route('/')
@admin_required
def list_transactions():
    type_filter = request.args.get('type', '')
    query = Transaction.query
    if type_filter:
        query = query.filter_by(type=TransactionType(type_filter))
    transactions = query.order_by(Transaction.transaction_date.desc()).all()
    total_income = db.session.query(db.func.sum(Transaction.amount)).filter_by(type=TransactionType.income).scalar() or 0
    total_expenses = db.session.query(db.func.sum(Transaction.amount)).filter_by(type=TransactionType.expense).scalar() or 0
    balance = total_income - total_expenses
    return render_template('admin/transactions/list.html',
                           transactions=transactions,
                           total_income=total_income,
                           total_expenses=total_expenses,
                           balance=balance,
                           current_type=type_filter)


@transactions_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_transaction():
    if request.method == 'POST':
        transaction = Transaction(
            description=request.form['description'],
            amount=float(request.form['amount']),
            type=TransactionType(request.form['type']),
            category=request.form.get('category'),
            reference=request.form.get('reference'),
            transaction_date=datetime.strptime(request.form['transaction_date'], '%Y-%m-%d').date() if request.form.get('transaction_date') else datetime.utcnow().date()
        )
        db.session.add(transaction)
        db.session.commit()
        flash('Transaction added successfully.', 'success')
        return redirect(url_for('transactions.list_transactions'))
    return render_template('admin/transactions/add.html')


@transactions_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_transaction(id):
    transaction = Transaction.query.get_or_404(id)
    if request.method == 'POST':
        transaction.description = request.form['description']
        transaction.amount = float(request.form['amount'])
        transaction.type = TransactionType(request.form['type'])
        transaction.category = request.form.get('category')
        transaction.reference = request.form.get('reference')
        transaction.transaction_date = datetime.strptime(request.form['transaction_date'], '%Y-%m-%d').date() if request.form.get('transaction_date') else transaction.transaction_date
        db.session.commit()
        flash('Transaction updated successfully.', 'success')
        return redirect(url_for('transactions.list_transactions'))
    return render_template('admin/transactions/edit.html', transaction=transaction)


@transactions_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_transaction(id):
    transaction = Transaction.query.get_or_404(id)
    db.session.delete(transaction)
    db.session.commit()
    flash('Transaction deleted successfully.', 'success')
    return redirect(url_for('transactions.list_transactions'))
