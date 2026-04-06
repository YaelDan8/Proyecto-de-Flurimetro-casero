```mermaid
flowchart TD
  Start([INICIO;]);

  A1[Escribir la palabra 'imagen'];
  A2[Seleccionar la imagen a analizar formato jpeg o jpg preferentemente];
  A3[Presionar doble click izquierdo;\npara confirmar la región de interés;];

  B1{¿Se tienen las librerías?;};
  B2[Se buscan las librerías desde MATLAB;];
  B3[Esperar a que se descarguen;\ncompletamente las librerías de MATLAB;];

  C1{¿Se quiere utilizar;\nuna imagen o una webcam?;};

  D1[Se crea la ROI usando click izquierdo;\ny dibujando el cuadrado de interés;];
  D2[Esperar a que MATLAB analice la ROI;\nseleccionada en la imagen;];

  E1[Escribir la palabra 'webcam';];
  E2[Colocar el número de webcam a utilizar leer nombre y número asociado];

  F1[Se pueden guardar los datos;];
  F2[Usar 'clear all' para resetear la consola;];

  G[Se obtiene el color, el valor en longitud de onda;\ny la gráfica con su respectiva intensidad;];

  End([FIN;]);

  %% Flujo
  Start -->  B1 -->|SI;| C1;
  B1 -->|NO;| B2;
  B2 --> B3;
  B3 --> Start;
  
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
