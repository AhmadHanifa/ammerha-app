import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import '../app/theme.dart';

/// "أنا عايش برّا سوريا": the request is followed from abroad.
class AbroadField extends StatelessWidget {
  const AbroadField({super.key, required this.remote, required this.onChanged, required this.country});

  final bool remote;
  final ValueChanged<bool> onChanged;
  final TextEditingController country;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: remote,
          onChanged: onChanged,
          title: const Text('أنا عايش برّا سوريا', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          subtitle: Text('بتتابع كل مرحلة بالصور من مكانك.', style: Theme.of(context).textTheme.bodySmall),
        ),
        if (remote)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: country,
              decoration: const InputDecoration(hintText: 'وين عايش؟ مثلاً ألمانيا'),
            ),
          ),
      ],
    );
  }
}

/// The code a real estate agency gave the buyer; checked as it is typed.
class AgencyCodeField extends StatefulWidget {
  const AgencyCodeField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<AgencyCodeField> createState() => _AgencyCodeFieldState();
}

class _AgencyCodeFieldState extends State<AgencyCodeField> {
  Timer? _debounce;
  String? _agency;
  var _checked = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    setState(() {
      _agency = null;
      _checked = false;
    });
    final code = value.trim();
    if (code.length < 3 || !AppConfig.hasBackend) return;
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final name = await Supabase.instance.client
            .rpc('check_agency_code', params: {'p_code': code})
            .timeout(AppConfig.requestTimeout);
        if (mounted && widget.controller.text.trim() == code) {
          setState(() {
            _agency = name as String?;
            _checked = true;
          });
        }
      } catch (_) {
        // Offline: the code still goes with the request and is checked there.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _changed,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'كود المكتب العقاري (إذا في)'),
        ),
        if (_checked)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _agency == null ? 'ما لقينا مكتب بهالكود' : 'من طرف: $_agency',
              style: TextStyle(fontSize: 13, color: _agency == null ? AppColors.priceUp : AppColors.primaryDark),
            ),
          ),
      ],
    );
  }
}
