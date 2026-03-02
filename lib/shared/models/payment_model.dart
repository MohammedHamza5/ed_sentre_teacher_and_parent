import 'enums.dart';

/// Invoice Model - Maps to public.student_invoices table
class InvoiceModel {
  final String id;
  final String studentId;
  final String centerId;
  final int month;
  final int year;
  final double totalAmount;
  final double paidAmount;
  final double discountAmount;
  final PaymentStatus status;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const InvoiceModel({
    required this.id,
    required this.studentId,
    required this.centerId,
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.paidAmount,
    this.discountAmount = 0,
    required this.status,
    this.dueDate,
    this.paidDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      centerId: json['center_id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'center_id': centerId,
      'month': month,
      'year': year,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'discount_amount': discountAmount,
      'status': status.name,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'paid_date': paidDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  double get remainingAmount => totalAmount - paidAmount - discountAmount;

  String get monthName {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  String get displayPeriod => '$monthName $year';
}

/// Payment Model - Maps to public.payments table
class PaymentModel {
  final String id;
  final String centerId;
  final String? studentId;
  final double amount;
  final String? paymentMethod;
  final DateTime? paymentDate;
  final String? referenceNumber;
  final String? notes;
  final PaymentStatus status;
  final String? receiptNumber;
  final String? monthYear;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields
  final String? courseName;
  final String? centerName;

  const PaymentModel({
    required this.id,
    required this.centerId,
    this.studentId,
    required this.amount,
    this.paymentMethod,
    this.paymentDate,
    this.referenceNumber,
    this.notes,
    required this.status,
    this.receiptNumber,
    this.monthYear,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.courseName,
    this.centerName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String? ?? '',
      centerId: json['center_id'] as String? ?? '',
      studentId: json['student_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : null,
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      receiptNumber: json['receipt_number'] as String?,
      monthYear: json['month_year'] as String?,
      groupId: json['group_id'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      courseName: json['course_name'] as String?,
      centerName: json['center_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'center_id': centerId,
      'student_id': studentId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate?.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'notes': notes,
      'status': status.name,
      'receipt_number': receiptNumber,
      'month_year': monthYear,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayMethod {
    switch (paymentMethod) {
      case 'cash':
        return 'نقدي';
      case 'bank':
        return 'بنكي';
      case 'electronic_wallet':
      case 'wallet':
        return 'محفظة إلكترونية';
      case 'visa':
        return 'فيزا';
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'instapay':
        return 'انستاباي';
      default:
        return paymentMethod ?? 'غير محدد';
    }
  }
}
