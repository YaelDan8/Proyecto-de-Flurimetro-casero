%Programa de Flurimetro para la enselanza de la física.
%== Actulizado en 2026 ==
% === Preguntar al usuario ===
modo = input('¿Quieres utilizar la webcam o una imagen? (escribe "webcam" o "imagen"): ', 's');

if strcmpi(modo, 'webcam')
    % === Lista de cámaras disponibles ===
    camList = webcamlist;
    disp('Cámaras disponibles:');
    for i = 1:length(camList)
        fprintf('%d: %s\n', i, camList{i});
    end
    choice = input('Escribe el número de la cámara: ');

    if choice >= 1 && choice <= length(camList)
        cam = webcam(choice);
        disp(['Cámara seleccionada: ', camList{choice}]);
    else
        error('Selección inválida.');
    end

    % === Capturar imagen desde webcam ===
    disp('Capturando imagen...');
    capturedImage = snapshot(cam);

elseif strcmpi(modo, 'imagen')
    % === Seleccionar imagen desde archivo ===
    [file, path] = uigetfile({'*.jpg;*.png;*.bmp','Archivos de imagen (*.jpg, *.png, *.bmp)'}, ...
                              'Selecciona una imagen');
    if isequal(file,0)
        error('No seleccionaste ninguna imagen.');
    else
        disp(['Imagen seleccionada: ', fullfile(path, file)]);
        capturedImage = imread(fullfile(path, file));
    end
else
    error('Opción inválida. Escribe "webcam" o "imagen".');
end

% === Procesar imagen (ROI y ajuste) ===
capturedImage = im2double(capturedImage);
capturedImage = capturedImage .^ 0.8; % aumenta sensibilidad al rojo

figure, imshow(capturedImage), title('Imagen capturada o cargada');

% === Selección de ROI ===
disp('Selecciona la ROI en la imagen...');
roi = drawrectangle; % el usuario dibuja la ROI
roiMask = createMask(roi);
roiImage = bsxfun(@times, capturedImage, cast(roiMask, 'like', capturedImage));

figure, imshow(roiImage), title('ROI seleccionada');


% === Seleccionar ROI ===
disp('Selecciona el área a analizar y pulsa doble clic...');
h = drawrectangle('Color','r');
wait(h);
roiPos = round(h.Position);
roiImage = imcrop(capturedImage, roiPos);
close;
figure, imshow(roiImage), title('Área seleccionada');

% === Calcular promedios RGB en ROI ===
meanRGB = squeeze(mean(mean(double(roiImage),1),2));
rMean = meanRGB(1);
gMean = meanRGB(2);
bMean = meanRGB(3);

% === Clasificación basada en RGB (solo para rojos) ===
if rMean > 0.6 && gMean < 0.1 && bMean < 0.1
    tipoFuente = 'Rojo(~600-625 nm)';
    lambdaDominante = 625;
    usarHSV = false;
elseif rMean > 0.65 && gMean > 0.1 && bMean > 0.15
    tipoFuente = 'Rojo Láser (~650 nm)';
    lambdaDominante = 650;
    usarHSV = false;
elseif rMean > 0.55 && gMean < 0.08 && bMean < 0.09
    tipoFuente = 'Rojo anaranjado (~616 nm)';
    lambdaDominante = 616;
    usarHSV = false;
else
    usarHSV = true;
end

% === Si no es rojo, aplicar flujo HSV ===
if usarHSV
    hsvImage = rgb2hsv(roiImage);
    H = hsvImage(:,:,1);
    S = hsvImage(:,:,2);
    V = hsvImage(:,:,3);

    % Corregir wrap del matiz rojo
    H(H > 0.9) = H(H > 0.9) - 1;
    H = mod(H, 1);

    % Filtrar píxeles válidos
    mask = (V > 0.10) & (S > 0.10);
    Hsel = H(mask);

    if isempty(Hsel)
        error('No se detectaron píxeles válidos en la ROI. Intenta con otra región más brillante.');
    end

    % Convertir Hue a longitud de onda
    lambda = hueToLambda(Hsel);

    % Histograma espectral
    edges = 380:2:780;
    [counts, centers] = histcounts(lambda, edges);
    centers = (edges(1:end-1) + edges(2:end))/2;

    % Suavizado
    window = 9;
    kernel = ones(1, window) / window;
    smoothCounts = conv(counts, kernel, 'same');

    % Detectar picos
    [peakVals, peakIdx] = findpeaks(smoothCounts, centers, ...
        'MinPeakProminence', max(smoothCounts)*0.03, ...
        'MinPeakDistance', 8);

    lambdaDominante = mean(lambda);
    tipoFuente = classifyColor(lambdaDominante);
else
    % Para rojos: graficamos una curva plana y solo la línea dominante
    centers = 380:2:780;
    smoothCounts = zeros(size(centers));
    peakIdx = lambdaDominante;
    peakVals = 1;
end
fprintf('\n=== Picos de emisión detectados ===\n');
if isempty(peakIdx)
    fprintf('⚠️ No se detectaron picos claros.\n');
else
    for i = 1:length(peakIdx)
        colorName = classifyColor(peakIdx(i));
        fprintf('Pico %d: %.1f nm - %s - Intensidad relativa %.2f\n', ...
            i, peakIdx(i), colorName, peakVals(i)/max(smoothCounts));
    end
end

fprintf('\n Clasificación espectral \n');
fprintf('rMean = %.2f, gMean = %.2f, bMean = %.2f\n', rMean, gMean, bMean);
fprintf('→ Fuente detectada: %s\n', tipoFuente);
fprintf('\nλ dominante estimada: %.1f nm (%s)\n', lambdaDominante, tipoFuente);

% === Mostrar ROI con etiqueta ===
figure, imshow(roiImage), title('Clasificación espectral');
text(10, 30, tipoFuente, 'Color','w', 'FontSize',14, 'FontWeight','bold', ...
     'BackgroundColor','black', 'Margin',5);
%%
% === Graficar espectro ===
figure;
hold on;
for i = 1:length(centers)-1
    rgb = wavelengthToRGB(centers(i));
    fill([centers(i), centers(i+1), centers(i+1), centers(i)], ...
         [0, 0, 1.05, 1.05], rgb, 'EdgeColor', 'none');
end
%plot(centers, smoothCounts / max(max(smoothCounts),1), 'k', 'LineWidth', 2);

% === Añadir gaussiana centrada en λ dominante ===
sigma = 15; % ancho de la gaussiana en nm
gaussCurve = exp(-((centers - lambdaDominante).^2) / (2*sigma^2));
gaussCurve = gaussCurve / max(gaussCurve); % normalizar
plot(centers, gaussCurve, 'k', 'LineWidth', 2); % dibujar gaussiana en negro

% Línea vertical en λ dominante
xline(lambdaDominante, '--w', sprintf('%s (%.0f nm)', tipoFuente, lambdaDominante), ...
    'LabelVerticalAlignment','bottom', 'LabelHorizontalAlignment','center', ...
    'FontWeight','bold', 'FontSize',10, 'Color','w');

xlabel('Longitud de onda (nm)');
ylabel('Intensidad normalizada');
title('Espectro de emisión detectado desde ROI');
xlim([380 780]);
ylim([0 1.2]);
set(gca,'Color','k','Layer','top');
box on;


%%
% === Función Hue → λ ===
function lambda = hueToLambda(hue)
    hueDeg = hue * 360;
    lambda = zeros(size(hueDeg));
    for i = 1:numel(hueDeg)
        h = hueDeg(i);

        if h < 5
            lambda(i) = 650 - (h/5)*(650-640);       % Rojo láser
        elseif h < 15
            lambda(i) = 640 - ((h-5)/10)*(640-625);  % Rojo LED
        elseif h < 25
            lambda(i) = 625 - ((h-15)/10)*(625-610); % Rojo anaranjado
        elseif h < 17
            lambda(i) = 625 - ((h-15)/2)*(625-621); % 15°–17° → 625–621 nm
        elseif h < 19
            lambda(i) = 621 - ((h-17)/2)*(621-618); % 17°–19° → 621–618 nm
        elseif h < 21
            lambda(i) = 618 - ((h-19)/2)*(618-616); % 19°–21° → 618–616 nm
        elseif h < 23
            lambda(i) = 616 - ((h-21)/2)*(616-613); % 21°–23° → 616–613 nm
        elseif h < 60
            lambda(i) = 610 - ((h-25)/35)*(610-580); % Naranja-amarillo
        elseif h < 120
            lambda(i) = 580 - ((h-60)/60)*(580-530); % Verde
        elseif h < 180
            lambda(i) = 530 - ((h-120)/60)*(530-500);% Cian
        elseif h < 240
            lambda(i) = 500 - ((h-180)/60)*(500-470);% Azul
        elseif h < 300
            lambda(i) = 470 - ((h-240)/60)*(470-420);% Azul-violeta
        else
            lambda(i) = 420 - ((h-300)/60)*(420-380);% Violeta
        end
    end
end

% === λ → RGB ===
function rgb = wavelengthToRGB(wavelength)
    if wavelength >= 380 && wavelength <= 440
        attenuation = 0.3 + 0.7 * (wavelength - 380) / (440 - 380);
        R = ((-(wavelength - 440) / (440 - 380)) * attenuation);
        G = 0.0;
        B = (1.0 * attenuation);
    elseif wavelength >= 440 && wavelength <= 490
        R = 0.0;
        G = (wavelength - 440) / (490 - 440);
        B = 1.0;
    elseif wavelength >= 490 && wavelength <= 510
        R = 0.0;
        G = 1.0;
        B = -(wavelength - 510) / (510 - 490);
    elseif wavelength >= 510 && wavelength <= 580
        R = (wavelength - 510) / (580 - 510);
        G = 1.0;
        B = 0.0;
    elseif wavelength >= 580 && wavelength <= 625
        R = 1.0;
        G = -(wavelength - 625) / (625 - 580);
        B = 0.0;
    elseif wavelength >= 625 && wavelength <= 780
        attenuation = 0.3 + 0.7 * (780 - wavelength) / (780 - 625);
        R = (1.0 * attenuation);
        G = 0.0;
        B = 0.0;
    else
        R = 0.0; G = 0.0; B = 0.0;
    end
    rgb = [R, G, B];
end

% === Clasificación de color (ajustada) ===
function cname = classifyColor(lambda)
    if lambda >= 380 && lambda < 450
        cname = 'Violeta/Azul';
    elseif lambda >= 450 && lambda < 495
        cname = 'Azul';
    elseif lambda >= 495 && lambda < 530
        cname = 'Verde';
    elseif lambda >= 530 && lambda < 560
        cname = 'Verde-amarillo';
    elseif lambda >= 560 && lambda < 590
        cname = 'Amarillo';
    elseif lambda >= 590 && lambda < 610
        cname = 'Amarillo-anaranjado';
    elseif lambda >= 610 && lambda < 620
        cname = 'Rojo anaranjado';
    elseif lambda >= 620 && lambda < 635
        cname = 'Rojo (~600–625 nm)';
    elseif lambda >= 635 && lambda <= 655
        cname = 'Rojo Láser (~650 nm)';
    elseif lambda > 655 && lambda <= 780
        cname = 'Rojo profundo (>655 nm)';
    else
        cname = 'Fuera del visible';
    end
end
