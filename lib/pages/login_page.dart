import 'package:flutter/material.dart';

import '../datos.dart';
import '../theme.dart';
import 'datos_rancho_page.dart';
import 'legal_page.dart';
import 'nuevo_movimiento_page.dart';

// Login local. Si aún no hay usuarios, la misma pantalla sirve para crear la primera cuenta;
// después ya no se ofrece registrarse aquí, para que nadie entre solo con crear una cuenta nueva.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  final _rancho = CamposRancho.vacios(); // solo en el registro inicial
  bool _acepta = false; // términos y aviso de privacidad
  bool? _registro; // null mientras se consulta si hay usuarios
  bool _ocultar = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    hayUsuarios().then((hay) {
      if (mounted) setState(() => _registro = !hay);
    });
  }

  @override
  void dispose() {
    for (final c in [_nombre, _usuario, _password, _confirmar]) {
      c.dispose();
    }
    _rancho.dispose();
    super.dispose();
  }

  /// Revisa todo el registro antes de guardar nada, para no dejar el rancho a medias.
  String? get _errorRegistro {
    if (_nombre.text.trim().isEmpty || _usuario.text.trim().isEmpty) return 'Escribe tu nombre y un usuario';
    if (_password.text.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (_password.text != _confirmar.text) return 'Las contraseñas no coinciden';
    if (_rancho.error case final e?) return e;
    if (!_acepta) return 'Debes aceptar los Términos y condiciones y el Aviso de privacidad';
    return null;
  }

  Future<void> _enviar() async {
    setState(() {
      _error = null;
      _enviando = true;
    });
    String? error;
    if (_registro!) {
      error = _errorRegistro;
      if (error == null) {
        await iniciarRanchoNuevo(_rancho.rancho); // la app arranca con este rancho
        error = await registrar(_usuario.text, _nombre.text, _password.text);
      }
    } else if (!await iniciarSesion(_usuario.text, _password.text)) {
      error = 'Usuario o contraseña incorrectos';
    }
    // Si salió bien, la app cambia sola a la pantalla principal (usuarioActual).
    if (mounted) {
      setState(() {
        _error = error;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registro = _registro;
    return Scaffold(
      body: SafeArea(
        child: registro == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset('assets/icon/icon.png', width: 96, height: 96, semanticLabel: 'AgroRegister'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      registro ? 'Crea tu cuenta' : 'Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registro
                          ? 'Registra tu cuenta y los datos de tu rancho para empezar'
                          : 'Inicia sesión para administrar tu hato',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    FormTarjeta(
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (registro) ...[
                              const FormEtiqueta('Nombre', requerido: true),
                              FormCampo(controller: _nombre, hint: 'Ej. Juan Pérez', icon: Icons.badge_outlined),
                              const SizedBox(height: 14),
                            ],
                            const FormEtiqueta('Usuario', requerido: true),
                            FormCampo(controller: _usuario, hint: 'Ej. juan', icon: Icons.person_outline),
                            const SizedBox(height: 14),
                            const FormEtiqueta('Contraseña', requerido: true),
                            TextField(
                              controller: _password,
                              obscureText: _ocultar,
                              autofillHints: [registro ? AutofillHints.newPassword : AutofillHints.password],
                              onSubmitted: registro ? null : (_) => _enviar(),
                              decoration: _decoracion(
                                registro ? 'Mínimo 6 caracteres' : 'Tu contraseña',
                                IconButton(
                                  tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                  icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 20, color: AppColors.textMuted),
                                  onPressed: () => setState(() => _ocultar = !_ocultar),
                                ),
                              ),
                            ),
                            if (registro) ...[
                              const SizedBox(height: 14),
                              const FormEtiqueta('Confirmar contraseña', requerido: true),
                              TextField(
                                controller: _confirmar,
                                obscureText: _ocultar,
                                onSubmitted: (_) => _enviar(),
                                decoration: _decoracion('Repite la contraseña', null),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (registro) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(4, 8, 4, 10),
                        child: Text('Datos del rancho',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ),
                      ..._rancho.tarjetas(context, setState),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acepta,
                            activeColor: AppColors.primary,
                            semanticLabel: 'Acepto los Términos y condiciones y el Aviso de privacidad',
                            onChanged: (v) => setState(() => _acepta = v!),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('He leído y acepto los ', style: TextStyle(fontSize: 13)),
                                  _enlace('Términos y condiciones', const LegalPage.terminos()),
                                  const Text(' y el ', style: TextStyle(fontSize: 13)),
                                  _enlace('Aviso de privacidad', const LegalPage.privacidad()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration:
                            BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: TextStyle(fontSize: 13, color: AppColors.danger)),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _enviando ? null : _enviar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(registro ? 'Crear cuenta' : 'Iniciar sesión',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Texto subrayado que abre un documento legal.
  Widget _enlace(String texto, Widget pagina) => InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => pagina)),
        child: Text(texto,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                decoration: TextDecoration.underline)),
      );

  InputDecoration _decoracion(String hint, Widget? sufijo) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: AppColors.border),
    );
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
      prefixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
      suffixIcon: sufijo,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: borde,
      enabledBorder: borde,
      focusedBorder: borde.copyWith(borderSide: BorderSide(color: AppColors.primary)),
    );
  }
}
