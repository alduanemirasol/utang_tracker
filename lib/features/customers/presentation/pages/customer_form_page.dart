import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_snackbar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key, this.customerId});

  final String? customerId;

  bool get isEditing => customerId != null;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _isDirty = false;
  String? _nameError;
  bool _saving = false;
  bool _loaded = false;
  Customer? _existing;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _confirmBack() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Discard changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      context.pop();
    }
  }

  void _populate(Customer customer) {
    _existing = customer;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone ?? '';
    _notesController.text = customer.notes ?? '';
    _isDirty = false;
    _loaded = true;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameFocusNode.requestFocus();
      });
      return;
    }
    setState(() {
      _nameError = null;
      _saving = true;
    });

    try {
      if (widget.isEditing && _existing != null) {
        await ref.read(updateCustomerProvider)(
          Customer(
            id: _existing!.id,
            name: name,
            phone: _phoneController.text,
            notes: _notesController.text,
            createdAt: _existing!.createdAt,
            updatedAt: _existing!.updatedAt,
          ),
        );
        invalidateBusinessData(ref, customerId: _existing!.id);
      } else {
        final created = await ref.read(createCustomerProvider)(
          name: name,
          phone: _phoneController.text,
          notes: _notesController.text,
        );
        invalidateBusinessData(ref, customerId: created.id);
      }

      if (!mounted) return;
      _isDirty = false;
      AppSnackBar.success(
        context,
        widget.isEditing ? 'Customer updated' : 'Customer added',
      );
      context.pop();
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _nameError = e.message);
    } on AppException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !_loaded) {
      final async = ref.watch(customerDetailProvider(widget.customerId!));
      return async.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit customer')),
          body: const LoadingIndicator(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit customer')),
          body: Center(child: Text(e.toString())),
        ),
        data: (data) {
          if (data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit customer')),
              body: const Center(child: Text('Customer not found')),
            );
          }
          if (!_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _populate(data.customer));
            });
          }
          return _buildForm();
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit customer' : 'Add customer'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            AppTextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Name *',
              hint: 'Customer name',
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                _markDirty();
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _phoneController,
              label: 'Phone',
              hint: 'Optional',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Optional notes',
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: widget.isEditing ? 'Save changes' : 'Add customer',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
