import 'package:flutter/material.dart';
import 'app_text_field.dart';

class PasswordTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;

  const PasswordTextField({
    super.key,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.controller,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}
