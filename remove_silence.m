function Remover_Ruido()

Fs = 8000; %frequencia de amostragem
x = audiorecorder;  % por defeito ou seja sem parametros o MATLAB assume Fs = 8kHz, nBits = 8 e o canal = 1 (Mono) 
disp('Start speaking.') %inicio da gravação
recordblocking(x, 5);  %cria um ficheiro audio de 10 segundos do tipo asv
disp('End of Recording.'); %fim da gravação
T = getaudiodata(x); %armazena os dados(audio) num vector 
audiowrite('PDS_audio.wav', T,Fs); %guarda no ficheiro
T = audioread('PDS_audio.wav'); %Abre o ficheiro de som

figure
plot(T); %desenha o grafico do sinal
title('sinal original');

Y = awgn(T,30) % adiciona um ruido branco ao sinal lido
figure
plot(Y);% desenha o grafico do sinal + ruido 
title('sinal + ruido');
Ruido = []


Tempo_total = length(Y)/Fs;
Amostras_F = floor(0.2*Fs/Tempo_total);
THRESHOLD = 1.5;            % Define  o Threshold
for i=1:1:Amostras_F
     Ruido =[Ruido Y(i)];  
end

Media = mean (Ruido);
Var   = std  (Ruido);


 
% Calculo do SNR
%A formula que vou usar para calcular o SNR é a seguinte:
%SNRdB = 10log(Potencia Sinal / Potencia Ruido)


%Potencia do Sinal
Energia_Sinal = 0;
for i=1 : 1 : length(Y)
    Energia_Sinal = Energia_Sinal +Y(i).^2; 
end

Potencia_Sinal_Com_Ruido = ((1/(2*length(Y))) * Energia_Sinal);

%Potencia do Ruido
%Como vimos nas aulas de PDS podemos calcular a potencia do ruido 
%usando a formula E{x^2} = var^2 +mx^2 onde:
%E{x^2} Potencia do sinal(media quadrática)
%var^2  Potencia AC (variancia)
%mx^2   Potencia DC 

Potencia_Ruido = Media^2 + Var^2;
 
SNR = 10*log10((Potencia_Sinal_Com_Ruido - Potencia_Ruido )/Potencia_Ruido);
 
if SNR < 0
    THRESHOLD = 1;
    Freq_Corte = 2000;
end
if SNR > 0 
    THRESHOLD = 1.5;
    Freq_Corte = 2000;
end;
if SNR > 15
    THRESHOLD = 1.5;
    Freq_Corte = 1500;
end;

fnorm =Freq_Corte/(Fs/2); 
[B,A] = butter(10,fnorm,'low');   
Y = filter(B,A,Y);
figure
plot (Y);
title('sinal filtrado');

%Para todas as amostras vou usar a equaçao  de Mahalanobis 
%que nos permite determinar se este é uma voz ou silencio
%se forem voz na posiçao dessa amostra  no vetor fala 
%é colocada 1 se nao é colocada igual a zero

for i=1:1:length(Y)
   if(abs(Y(i)) > Media + THRESHOLD * Var)
       fala(i)=1; 
       
   else
       fala(i)=0;
   end
end


%Agora vamos primeiro calcular o numero total de pontos que usamos 
%e este nos ujuda a calcular o numero de frames porque ja sabemos o 
%numero de amostras de cada Frame. depois disso vamos organizar os 
%dados guardados no vetor em frames e analizamos esses frames como 
%sendo voz ou silencio, se u numero de amostras  igual a zero for 
%maior que o numero das iguais a 1 essa frame é sem voz, caso 
%contrario a frame possui voz 

Numero_Frames=floor(length(Y)/Amostras_F);
framesVoz=0;

for i=1:1:Numero_Frames
    voz=0;
    silencio=0;
    for j=i*Amostras_F-Amostras_F+1:1:(i*Amostras_F)
        if(fala(j)==1)
            voz=(voz+1);
        else
            silencio=silencio+1;
        end
    end

    %marcar as frames voz ou nao-voz
    if(voz>silencio)
        framesVoz=framesVoz+1;
        Vetor_Frames(i)=1;
    else
        Vetor_Frames(i)=0;
    end
end

sinalFinal=[];
%-----
for i=1:1:Numero_Frames
    if(Vetor_Frames(i)== 1)
        for j=i*Amostras_F-Amostras_F+1:1:(i*Amostras_F)
            sinalFinal= [sinalFinal Y(j)];
        end
    end
end

figure
plot(sinalFinal);
title('sinal final');
sound(sinalFinal,Fs);



end