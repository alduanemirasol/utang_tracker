import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_input.dart';
import 'package:utang_tracker/core/presentation/app_page_body.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  bool get isEditing => customerId != null;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    final result = await ref
        .read(getCustomerUseCaseProvider)
        .execute(widget.customerId!);
    switch (result) {
      case Success(data: final customer):
        _nameController.text = customer.name;
        _phoneController.text = customer.phone ?? '';
        _notesController.text = customer.notes ?? '';
      case Error():
        if (mounted) {
          context.showErrorSnackBar('Failed to load customer');
          context.pop();
        }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final Result<Customer> result;
    if (widget.isEditing) {
      result = await ref.read(updateCustomerUseCaseProvider).execute(
            id: widget.customerId!,
            name: _nameController.text,
            phone: _phoneController.text.isEmpty
                ? null
                : _phoneController.text,
            notes: _notesController.text.isEmpty
                ? null
                : _notesController.text,
          );
    } else {
      result = await ref.read(createCustomerUseCaseProvider).execute(
            name: _nameController.text,
            phone: _phoneController.text.isEmpty
                ? null
                : _phoneController.text,
            notes: _notesController.text.isEmpty
                ? null
                : _notesController.text,
          );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      switch (result) {
        case Success():
          ref.invalidate(customerListProvider);
          context.showSuccessSnackBar(
            widget.isEditing
                ? 'Customer updated successfully'
                : 'Customer created successfully',
          );
          context.pop();
        case Error(failure: final f):
          context.showErrorSnackBar(f.message);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Customer' : 'New Customer'),
      ),
      body: _isLoading
          ? const AppLoadingView()
          : SingleChildScrollView(
              padding: AppResponsive.of(context).scrollPadding(),
              child: AppConstrainedWidth(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppInput(
                        label: 'Customer Name',
                        controller: _nameController,
                        hintText: 'Enter customer name',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.space7),
                      AppInput(
                        label: 'Phone Number',
                        controller: _phoneController,
                        hintText: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.space7),
                      AppInput(
                        label: 'Notes',
                        controller: _notesController,
                        hintText: 'Optional notes',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.space10),
                      AppPrimaryButton(
                        label: 'Save',
                        onPressed: _save,
                        isLoading: _isSaving,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
