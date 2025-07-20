import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecuperarContrasenaPantalla extends StatefulWidget {
  const RecuperarContrasenaPantalla({super.key});

  @override
  State<RecuperarContrasenaPantalla> createState() =>
      _RecuperarContrasenaPantallaState();
}

class _RecuperarContrasenaPantallaState
    extends State<RecuperarContrasenaPantalla>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  bool _cargando = false;
  String? _mensaje;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _enviarRecuperacion() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _correoController.text.trim(),
      );
      setState(() {
        _mensaje =
            "Correo de recuperación enviado. Revisa tu bandeja de entrada.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _mensaje = e.message ?? "Error desconocido";
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF232526),
              Color(0xFF414345),
            ], // degradado más sutil
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              child: Card(
                elevation: 24,
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                shadowColor: Colors.black.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.blueAccent,
                          size: 48,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Recuperar Contraseña',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 28),
                        TextFormField(
                          controller: _correoController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.blueGrey.withOpacity(0.06),
                            labelText: "Correo electrónico",
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v!.contains('@') ? null : "Correo inválido",
                        ),
                        SizedBox(height: 24),
                        if (_mensaje != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _mensaje!.contains("enviado")
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: _mensaje!.contains("enviado")
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _mensaje!,
                                  style: TextStyle(
                                    color: _mensaje!.contains("enviado")
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _cargando
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _enviarRecuperacion();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: Colors.blueAccent,
                                elevation: 0,
                              ),
                              child: _cargando
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      "Enviar correo de recuperación",
                                      style: TextStyle(
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // BOTÓN DE VOLVER AL LOGIN
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            "← Volver al inicio de sesión",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
