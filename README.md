# Proyecto de construccion de un Espectroflurimetro casero
En el siguiente repositorio se encuentra el modelo 3D del montaje experimental así como el programa en MatLab para su uso libre (sí no se tienen las librerias descargasdas, matlab arrojará un error con instrucciones de intalación); también estan anexadas las intrucciónes de uso del programa. 

# Montaje experimental en 3D
En la imagen mostrada se puede apreciar el montaje experimental para llevar acabo la construcción del espectroflurimetro. Una vez construido el espectroflurimetro, en la siguiente sección se muestran los pasos a seguir para utilizar correctamente el codigo de MATLAB.
![Modeo 3D del montaje experimental del espectrofluorometro](Modelo3D_E3_editado.png)

# Instrucciones de uso del software
NOTA: Se debe considerar que las toolbox de computer vision, image processing y signal processing, fueron incliudas a partir de la version de MATLAB R2022b, estas toolbox no se enuentran en versiones anteriores de MATLAB.

```mermaid
flowchart TD
  Start([INICIO]);

  A1[Escribir la palabra 'imagen'];
  A2[Seleccionar la imagen a analizar en formato jpeg o jpg preferentemente.];
  A3[Presionar doble click izquierdo\npara confirmar la región de interés.];

  B1{¿Se tienen las toolboxes &#40librerías&#41?};
  B2[Se buscan las toolboxes desde MATLAB.];
  B3[En el área de home se busca el icono\ncon tres cubos de nombre 'Add-Ons'.];
  B4[Se desplegará un buscador donde se tienen\nque buscar las toolbox para image processing.];
  B5[Se elige la toolbox y se descarga.];

  C1{¿Se quiere utilizar\nuna imagen o una webcam?};

  D1[Se crea la ROI utilizando el click izquierdo del mouse, arrastrando el cursor dejando el click izquierdo apretado, también se puede ajustar el cuadrado de las esquinas marcadas.]
  D2[Esperar a que MATLAB analicé la ROI\nseleccionada en la imagen.];

  E1[Escribir la palabra 'webcam'];
  E2[Colocar el número de webcam a utilizar\n &#40 leer el nombre de la webcam con el numero asociado por el sistema &#41];

  F1[Se toma una captura de pantalla para guardar los datos.];
  F2[Usar 'clear all' para resetear la consola.];

  G[Se obtiene el color, el valor en longitud de onda\ny la gráfica con su respectiva intensidad.];

  End([FIN]);

  %% Flujo
  Start -->  B1 -->|SI| C1;
  B1 -->|NO| B2;
  B2 --> B3;
  B3 --> B4;
  B4 --> B5;
  B5 --> Start;
  
  C1 --> A1;
  C1 --> E1;
  
  A1 --> A2;
  E1 --> E2;

  A2 --> D1;
  E2 --> D1;
  D1 --> A3;

  A3 --> D2;
  D2 --> G;
  G --> F1;
  F1 --> F2;

  F2 --> End;
```
