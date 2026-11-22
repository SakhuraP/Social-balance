boolean modoDebug = false;
PFont fuenteJuego;
PImage fondoInicio;

PImage fondoInterfazEscritorio;
PImage fondoMinijuegos;
PImage imagenTarjetaTarea;

// Fondos de habitaciones
PImage cuarto2;
PImage cuarto1;

// Pantallas
int pantalla = 0;
// 0 = Menú principal
// 1 = Selección de personaje
// 2 = Nivel 1

// Transición de encendido tipo monitor, al entrar al cuarto.
final int DURACION_TRANSICION_ENCENDIDO = 1250;
boolean transicionEncendido = false;
long inicioTransicionEncendido = 0;

int personajeSeleccionado = 0;
// 0 = Ninguno, 1 = Chico, 2 = Chica, 3 = NoBin

// Objetos principales
Jugador jugador;
Escritorio escritorio;
HUD hud;
Cama cama;
Celular celular;

PImage imagenInstrucciones;
Instrucciones instrucciones;

GestorMinijuegos gestorMinijuegos;

// Imágenes del minijuego Memoria
PImage reversoMemoria;
PImage[] imagenesMemoria = new PImage[6];

// ================= SETUP =================

void setup() {

  fullScreen();

  // Mantener estilo Pixel Art
  noSmooth();
  // Fuente lógica de Java: disponible también en los equipos de los compañeros.
  fuenteJuego = new PFont(new java.awt.Font("SansSerif",java.awt.Font.BOLD,24),true);
  textFont(fuenteJuego);

  // Menú principal
  fondoInicio = loadImage("PantallaDeInicio.png");

  prepararPersonajes();

  // Habitaciones
  cuarto2 = loadImage("Cuarto2.png");
  cuarto1 = loadImage("Cuarto1.png");

  // Crear jugador (carga el nuevo spritesheet)
  jugador = new Jugador();

  // Escritorio
  escritorio = new Escritorio();

  // HUD
  hud = new HUD();
  cama = new Cama();
  celular = new Celular();

  // Instrucciones
  // Las instrucciones ahora se dibujan como texto sobre VentanaEmergente.
  instrucciones = new Instrucciones(imagenInstrucciones);

  // Minijuego
  gestorMinijuegos = new GestorMinijuegos();

  fondoInterfazEscritorio = loadImage("InterfazEscritorio.png");
  fondoMinijuegos = loadImage("VentanaEmergente.PNG");
  imagenTarjetaTarea = loadImage("TarjetaTarea.png");

  // Imágenes de las cartas de Memoria
  reversoMemoria = loadImage("ReversoTM.png");

  imagenesMemoria[0] = loadImage("BienestarTM.png");
  imagenesMemoria[1] = loadImage("EquilibrioTM.png");
  imagenesMemoria[2] = loadImage("PrivacidadTM.png");
  imagenesMemoria[3] = loadImage("RespetoTM.png");
  imagenesMemoria[4] = loadImage("TiempoTM.png");
  imagenesMemoria[5] = loadImage("CelularTM.png");
}


// ================= DRAW =================

void dibujarJuego() {

  // MENÚ PRINCIPAL
  if (pantalla == 0) {
    mostrarMenu();
  }

  // SELECCIÓN DE PERSONAJE
  else if (pantalla == 1) {
    mostrarSeleccionPersonaje();
  }

  // NIVEL 1
  else if (pantalla == 2) {

    // ================= HABITACIÓN =================

    // Cuarto1: Chica. Cuarto2: Chico y NoBin.
    PImage cuartoActual = personajeSeleccionado == 2 ? cuarto1 : cuarto2;
    if (cuartoActual != null) image(cuartoActual, 0, 0, ANCHO_JUEGO, ALTO_JUEGO);

    // ================= JUGADOR =================

    boolean puedeMoverse = !transicionEncendido && !hayInterfazAbierta() && focused;

    if (puedeMoverse) {
      jugador.actualizar();
    } else {
      jugador.detenerMovimiento();
    }

    jugador.mostrar();


    // ================= ESCRITORIO =================

    if (escritorio.interfazAbierta) escritorio.mostrarInterfaz();
    if (!hayInterfazAbierta()) mostrarAyudaRecorrido();


    // ================= HUD =================

    if (!escritorio.interfazAbierta) hud.mostrar();
    cama.mostrar();
    celular.mostrar();


    // ================= INSTRUCCIONES =================

    instrucciones.mostrar();


    // ================= MINIJUEGO =================

    gestorMinijuegos.mostrar();
  }

  // Efecto de encendido del monitor que revela la escena del cuarto.
  if (transicionEncendido) dibujarTransicionEncendido();

  // mostrarCoordenadas();

  if (modoDebug) {
    mostrarCuadricula();
  }
}

void iniciarTransicionEncendido() {
  pantalla = 2;
  jugador.detenerMovimiento();
  inicioTransicionEncendido = millis();
  transicionEncendido = true;
}

void dibujarTransicionEncendido() {
  float progreso = constrain(
    (millis() - inicioTransicionEncendido) / (float)DURACION_TRANSICION_ENCENDIDO,
    0, 1
  );
  float suave = progreso * progreso * (3 - 2 * progreso);
  float altoVisible = max(2, ALTO_JUEGO * suave);
  float bordeSuperior = (ALTO_JUEGO - altoVisible) / 2;
  float brillo = 1 - progreso;

  pushStyle();
  rectMode(CORNER);
  noStroke();

  // La pantalla comienza negra y se abre desde una línea horizontal central.
  fill(0);
  rect(0, 0, ANCHO_JUEGO, bordeSuperior);
  rect(0, bordeSuperior + altoVisible, ANCHO_JUEGO,
       ALTO_JUEGO - bordeSuperior - altoVisible);

  // Resplandor azulado en los bordes, como un monitor encendiéndose.
  fill(110, 220, 255, 190 * brillo);
  rect(0, bordeSuperior - 2, ANCHO_JUEGO, 4);
  rect(0, bordeSuperior + altoVisible - 2, ANCHO_JUEGO, 4);

  // Destello blanco de la línea central que desaparece al revelarse el cuarto.
  float altoDestello = max(2, 14 * brillo);
  fill(255, 255, 255, 220 * brillo);
  rect(0, ALTO_JUEGO / 2 - altoDestello / 2, ANCHO_JUEGO, altoDestello);
  popStyle();

  if (progreso >= 1) transicionEncendido = false;
}


void mostrarCuadricula() {

  pushStyle();

  // Cuadrícula cada 20 píxeles
  strokeWeight(1);

  for (int x = 0; x <= ANCHO_JUEGO; x += 20) {

    if (x % 100 == 0) {
      stroke(255, 120);
    } else {
      stroke(255, 35);
    }

    line(x, 0, x, ALTO_JUEGO);
  }

  for (int y = 0; y <= ALTO_JUEGO; y += 20) {

    if (y % 100 == 0) {
      stroke(255, 120);
    } else {
      stroke(255, 35);
    }

    line(0, y, ANCHO_JUEGO, y);
  }

  // Coordenadas del mouse
  noStroke();
  fill(15, 15, 20, 230);
  rect(10, ALTO_JUEGO - 45, 225, 35, 5);

  fill(255);
  textAlign(LEFT, CENTER);
  textSize(15);

  text(
    "X: " + mouseJuegoX() + "  Y: " + mouseJuegoY(),
    20,
    ALTO_JUEGO - 28
    );

  // Cruz de posición del mouse
  stroke(255, 200, 100);
  strokeWeight(1);

  line(mouseJuegoX() - 10, mouseJuegoY(),
    mouseJuegoX() + 10, mouseJuegoY());

  line(mouseJuegoX(), mouseJuegoY() - 10,
    mouseJuegoX(), mouseJuegoY() + 10);

  popStyle();
}


// ================= COORDENADAS =================

// void mostrarCoordenadas() {
//
//   fill(0, 180);
//   noStroke();
//   rect(10, 10, 170, 45);
//
//   fill(255);
//   textAlign(LEFT, CENTER);
//   textSize(18);
//
//   text("X: " + mouseJuegoX() + " Y: " + mouseJuegoY(), 20, 32);
// }