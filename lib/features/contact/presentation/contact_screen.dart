import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/validators.dart';
import 'package:craftbloom/shared/widgets/page_header.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final subject = Uri.encodeComponent(_subjectCtrl.text.trim());
    final body = Uri.encodeComponent(
      'Nombre: ${_nameCtrl.text.trim()}\nEmail: ${_emailCtrl.text.trim()}\n\n${_messageCtrl.text.trim()}',
    );
    await _launchUrl('mailto:${AppConfig.contactEmail}?subject=$subject&body=$body');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: AppStrings.contactUs,
                  subtitle: '¿Tenés alguna consulta? Contactanos por el medio que prefieras.',
                ),
                const SizedBox(height: AppSizes.md),

              // Botones de contacto rápido
              _ContactButton(
                icon: Icons.camera_alt_outlined,
                label: 'Instagram',
                subtitle: AppConfig.instagramHandle,
                color: const Color(0xFFE1306C),
                onTap: () => _launchUrl(AppConfig.instagramUrl),
              ),
              const SizedBox(height: AppSizes.md),
              _ContactButton(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                subtitle: AppConfig.whatsappNumber,
                color: const Color(0xFF25D366),
                onTap: () => _launchUrl('${AppConfig.whatsappUrl}?text=${Uri.encodeComponent("Hola! Quiero consultar sobre un pedido.")}'),
              ),
              if (AppConfig.facebookUrl.isNotEmpty) ...[
                const SizedBox(height: AppSizes.md),
                _ContactButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  subtitle: 'CraftBloom',
                  color: const Color(0xFF1877F2),
                  onTap: () => _launchUrl(AppConfig.facebookUrl),
                ),
              ],
              const SizedBox(height: AppSizes.xl),
              const Divider(),
              const SizedBox(height: AppSizes.xl),

              // Formulario de email
              Text('Envianos un mensaje', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSizes.md),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => Validators.required(v, 'El nombre'),
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: AppStrings.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.subject,
                        prefixIcon: Icon(Icons.subject_outlined),
                      ),
                      validator: (v) => Validators.required(v, 'El asunto'),
                    ),
                    const SizedBox(height: AppSizes.md),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: AppStrings.contactMessage,
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 72),
                          child: Icon(Icons.message_outlined),
                        ),
                      ),
                      validator: (v) => Validators.minLength(v, 10, 'El mensaje'),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      label: const Text(AppStrings.sendMessage),
                      onPressed: _sendEmail,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                child: Icon(icon, color: Colors.white, size: AppSizes.iconLg),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleLarge),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
