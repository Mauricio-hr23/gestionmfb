import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestion_mfb/pantallas/chofer/chofer_panel_pantalla.dart';
import 'package:gestion_mfb/pantallas/pedidos/crear_pedido_pantalla.dart';
import 'package:gestion_mfb/pantallas/pedidos/lista_pedidos_pantalla.dart';
import 'package:provider/provider.dart';

// Importa tus providers
import 'proveedores/vehiculo_proveedor.dart';
import 'proveedores/chofer_proveedor.dart';

// Importa tus pantallas principales
import 'pantallas/autenticacion/iniciar_sesion_pantalla.dart';
import 'pantallas/autenticacion/registrar_pantalla.dart';
import 'pantallas/splash_pantalla.dart';
import 'pantallas/autenticacion/recuperar_contrasena_pantalla.dart';
import 'pantallas/administrador/lista_usuarios_pantalla.dart';
import 'pantallas/administrador/admin_menu_pantalla.dart';

// Importa pantallas de gestión de vehículos y choferes
import 'pantallas/vehiculos/lista_vehiculos_pantalla.dart';
import 'pantallas/chofer/lista_choferes_pantalla.dart';
import 'pantallas/chofer/agregar_chofer_pantalla.dart';

// Si tienes dashboards o paneles por rol, los puedes importar aquí
// import 'pantallas/administrador/admin_panel_pantalla.dart';
// import 'pantallas/chofer/chofer_panel_pantalla.dart';
// import 'pantallas/cliente/cliente_panel_pantalla.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MFBApp());
}

class MFBApp extends StatelessWidget {
  const MFBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehiculoProveedor()),
        ChangeNotifierProvider(create: (_) => ChoferProveedor()),
        // Agrega otros providers aquí si los necesitas
      ],
      child: MaterialApp(
        title: 'Gestión MFB',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          // Agrega tu propio ThemeData si quieres un look más personalizado/moderno
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashPantalla(),
          '/login': (context) => IniciarSesionPantalla(),
          '/registro': (context) => RegistrarPantalla(),
          '/recuperar': (context) => RecuperarContrasenaPantalla(),
          '/lista_usuarios': (context) => ListaUsuariosPantalla(),
          '/vehiculos': (context) => ListaVehiculosPantalla(),
          '/choferes': (context) => ListaChoferesPantalla(),
          '/admin_menu': (context) => AdminMenuPantalla(),
          '/agregar_chofer': (context) => AgregarChoferPantalla(),
          '/crear-pedido': (context) => CrearPedidoPantalla(),
          '/lista-pedidos': (context) => ListaPedidosPantalla(),
          '/panel_chofer': (context) => PanelChoferPantalla(),
          //'/seguimiento-pedido': (context) => SeguimientoPedidoPantalla(),

          // '/panel_admin': (context) => PanelAdminPantalla(),
          // '/panel_chofer': (context) => PanelChoferPantalla(),
          // '/panel_cliente': (context) => PanelClientePantalla(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
