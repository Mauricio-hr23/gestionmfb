const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.crearChofer = functions.https.onCall(async (data, context) => {
  // ===== DEBUG: imprime información del contexto de autenticación =====
  console.log('CONTEXT.AUTH:', context.auth);
  console.log('DATA:', data);

  // 1. Verifica que está autenticado
  const uidAdmin = context.auth?.uid;
  if (!uidAdmin) {
    console.log("❌ ERROR: No hay sesión activa (context.auth null)");
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Debes iniciar sesión como administrador."
    );
  }

  // 2. (Opcional) Verifica que realmente es administrador en Firestore
  const usuarioDoc = await admin.firestore().collection('usuarios').doc(uidAdmin).get();
  if (!usuarioDoc.exists) {
    console.log(`❌ ERROR: No existe documento de usuario para UID ${uidAdmin}`);
    throw new functions.https.HttpsError(
      "not-found",
      "No existe documento de usuario para este UID."
    );
  }

  if (usuarioDoc.data().rol !== 'administrador') {
    console.log(`❌ ERROR: UID ${uidAdmin} no es administrador. Rol: ${usuarioDoc.data().rol}`);
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo administradores pueden crear choferes."
    );
  }

  // 3. Toma los datos del chofer
  const { nombre, correo, password, estado } = data;

  // 4. Verifica que no exista ya un usuario con ese correo
  try {
    const existingUser = await admin.auth().getUserByEmail(correo);
    if (existingUser) {
      throw new functions.https.HttpsError(
        "already-exists",
        "Ya existe un usuario con ese correo."
      );
    }
  } catch (err) {
    // Si el usuario no existe, continúa (Firebase lanza error si no existe, así que está bien dejarlo vacío aquí)
  }

  // 5. Crea el usuario en Auth
  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email: correo,
      password: password,
      displayName: nombre,
      disabled: estado === "inactivo"
    });
  } catch (err) {
    console.log("❌ ERROR: No se pudo crear usuario en Auth:", err);
    throw new functions.https.HttpsError(
      "internal",
      `No se pudo crear el usuario en Auth: ${err.message || err}`
    );
  }

  // 6. Crea el documento en 'usuarios' en Firestore
  try {
    await admin.firestore().collection('usuarios').doc(userRecord.uid).set({
      nombre,
      correo,
      rol: 'chofer',
      estado,
    });
  } catch (err) {
    console.log("❌ ERROR: No se pudo crear usuario en Firestore:", err);
    throw new functions.https.HttpsError(
      "internal",
      `No se pudo crear el documento en Firestore: ${err.message || err}`
    );
  }

  console.log(`✅ Chofer creado exitosamente: ${correo} (${userRecord.uid}) por admin ${uidAdmin}`);
  return { message: "Chofer creado exitosamente" };
});
