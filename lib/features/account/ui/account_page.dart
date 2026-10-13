import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/paper_background.dart';
import '../../onboarding/register_screen.dart' show OfficeBehind;

/// The page every account screen is written on: the detective's office out
/// of focus behind one ruled paper slip, as on the detective registration
/// page. A back arrow, the agency's eyebrow, the page's [title], its
/// [content], and [actions] below the paper (the glass buttons).
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.eyebrow = 'LONDON DETECTIVE AGENCY',
    this.actions = const [],
    this.onBack,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  /// What is written on the paper, under the title.
  final List<Widget> content;
  final List<Widget> actions;

  /// Null: no back arrow.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Stack(
      children: [
        const Positioned.fill(child: OfficeBehind()),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            foregroundColor: AppColors.goldLight,
            automaticallyImplyLeading: false,
            leading: onBack == null
                ? null
                : IconButton(
                    tooltip: 'Back',
                    icon: const InkIcon(InkGlyph.back),
                    style: IconButton.styleFrom(backgroundColor: AppColors.navyDeep.withValues(alpha: 0.45)),
                    onPressed: onBack,
                  ),
          ),
          body: InkSurface(
            night: true,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: typing ? AppSpace.sm : AppSpace.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PaperSheet(
                          ruled: true,
                          tilt: -0.004,
                          padding: EdgeInsets.fromLTRB(
                            AppSpace.lg,
                            typing ? AppSpace.md : AppSpace.xl,
                            AppSpace.lg,
                            AppSpace.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(eyebrow, textAlign: TextAlign.center, style: AppText.eyebrow()),
                              const SizedBox(height: AppSpace.sm),
                              Text(title, textAlign: TextAlign.center, style: AppText.title(size: 24)),
                              if (subtitle case final s?) ...[
                                const SizedBox(height: AppSpace.xs),
                                Text(s, textAlign: TextAlign.center, style: AppText.aside()),
                              ],
                              const SizedBox(height: AppSpace.sm),
                              const Center(child: OrnamentRule(width: 96)),
                              const SizedBox(height: AppSpace.md),
                              ...content,
                            ],
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          SizedBox(height: typing ? AppSpace.md : AppSpace.lg),
                          ...actions,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A line on the paper to write on (the registration page's line): a
/// small label above, the writing in navy, the line darkening in ink when
/// written on.
class LedgerField extends StatefulWidget {
  const LedgerField({
    super.key,
    required this.label,
    required this.controller,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<LedgerField> createState() => _LedgerFieldState();
}

class _LedgerFieldState extends State<LedgerField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    UnderlineInputBorder line(Color c, [double w = AppLine.rule]) =>
        UnderlineInputBorder(borderSide: BorderSide(color: c, width: w));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: widget.password && _hidden,
        enableSuggestions: !widget.password,
        autocorrect: false,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        onSubmitted: widget.onSubmitted,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: AppText.bodyText(size: 18, color: AppColors.navy),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: AppText.bodyText(size: 15, color: AppColors.inkBrown),
          floatingLabelStyle: AppText.eyebrow(color: AppColors.inkBrown),
          counterText: '',
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          border: line(AppLine.faint(0.45)),
          enabledBorder: line(AppLine.faint(0.45)),
          focusedBorder: line(AppColors.inkBrown),
          disabledBorder: line(AppLine.faint(0.25)),
          suffixIcon: widget.password
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: InkIcon(_hidden ? InkGlyph.eye : InkGlyph.lock, size: AppIconSize.small, color: AppColors.inkBrown),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}

/// One calm line under the fields: what went wrong (try-again ink) or what
/// happened (navy). Read out when it appears.
class AccountNote extends StatelessWidget {
  const AccountNote(this.text, {super.key, this.problem = true});

  final String text;
  final bool problem;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.bodyText(size: 15, color: problem ? AppColors.tryAgain : AppColors.navy),
          ),
        ),
      );
}

/// A label and its value on one line of the paper (the account page).
class AccountLine extends StatelessWidget {
  const AccountLine({super.key, required this.label, required this.value, this.glyph});

  final String label;
  final String value;
  final InkGlyph? glyph;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (glyph case final g?) ...[
              InkIcon(g, size: AppIconSize.small, color: AppColors.goldDeep),
              const SizedBox(width: AppSpace.sm),
            ],
            Text(label, style: AppText.eyebrow(color: AppColors.inkBrown)),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(value, textAlign: TextAlign.end, style: AppText.bodyText(size: 16, color: AppColors.navy)),
            ),
          ],
        ),
      );
}
