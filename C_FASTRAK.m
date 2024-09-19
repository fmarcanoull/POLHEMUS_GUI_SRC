%% Autor: Francisco Marcano. 2023.
%% Ejemplo: configurarFASTRACK('COM37')
classdef C_FASTRAK
    properties (Access = public)
        bauds = 115200;
        comando_activarModoContinuo = 'C';
        comando_activarModoAscii = 'F';
        comando_activarPuerto1 = 'l1,1';
        comando_activarPuerto2 = 'l2,1';
        comando_activarPuerto3 = 'l3,1';
        comando_activarPuerto4 = 'l4,1';
        comando_activarUnidadesMetricas = 'u';
        comando_desactivarPuerto1 = 'l1,0';
        comando_desactivarPuerto2 = 'l2,0';
        comando_desactivarPuerto3 = 'l3,0';
        comando_desactivarPuerto4 = 'l4,0';
        comando_detenerModoContinuo = 'c';
        comando_modoBoton = 'e1,1';
        comando_solicitarDato = 'P';
        comando_solicitarConfiguracionDeControl = 'X';
        dispositivoSerial = []
        puerto = [];
    end
    
    methods (Access = public) 
        function obj = C_FASTRAK()
        end

        function escribirComandoConCR(~,dispositivoSerial,comando)
            write(dispositivoSerial,[uint8(comando) 13],"uint8");
        end

        function escribirComando(~,dispositivoSerial,comando)
            write(dispositivoSerial,uint8(comando),"uint8");
        end

        function respuesta = leerRespuesta(~,dispositivoSerial)
            respuesta = [];
            numeroCaracteres = dispositivoSerial.NumBytesAvailable;
            if (numeroCaracteres > 0)
                respuesta = read(dispositivoSerial,numeroCaracteres,"uint8");     
            end
        end

        function [puerto,sensores,obj]  = iniciarFASTRAK(obj)
            puerto = [];
            sensores = [];
            antiguaCadenaDeConfiguracion = [];
            puertosDisponibles = serialportlist();
            A = [];
            for ix = 1:length(puertosDisponibles)
                try
                    %%% Resolver este issue después
                    switch puertosDisponibles{ix}
                        case 'COM3'
                            continue;
                        case 'COM4'
                            continue;
                    end
                    obj.dispositivoSerial = serialport(puertosDisponibles{ix},obj.bauds,'Timeout',0.1);
                    obj.puerto =  puertosDisponibles{ix};
                catch 
                    %%% omitir
                end
                antiguaCadenaDeConfiguracion = [];
                if ~isempty(obj.dispositivoSerial)
                    obj.escribirComandoConCR(obj.dispositivoSerial,obj.comando_activarPuerto1);
                    pause(0.3);
                    obj.escribirComandoConCR(obj.dispositivoSerial,obj.comando_modoBoton);
                    pause(0.3);
                    obj.escribirComando(obj.dispositivoSerial,obj.comando_detenerModoContinuo);
                    obj.escribirComando(obj.dispositivoSerial,obj.comando_activarUnidadesMetricas);
                    obj.escribirComando(obj.dispositivoSerial,obj.comando_activarModoAscii);
                    obj.escribirComandoConCR(obj.dispositivoSerial,obj.comando_solicitarConfiguracionDeControl);
                    pause(0.3);
                    antiguaCadenaDeConfiguracion = obj.leerRespuesta(obj.dispositivoSerial);
                    antiguaCadenaDeConfiguracion = strtrim(char(antiguaCadenaDeConfiguracion(4:end)));
                    nuevaCadenaDeConfiguracion = 'Fastrak1234567890';
                    obj.escribirComandoConCR(obj.dispositivoSerial,[obj.comando_solicitarConfiguracionDeControl uint8(nuevaCadenaDeConfiguracion)]);
                    pause (0.3);
                    obj.escribirComandoConCR(obj.dispositivoSerial,obj.comando_solicitarConfiguracionDeControl);
                    pause (0.3);
                    cadenaDeConfiguracion = obj.leerRespuesta(obj.dispositivoSerial);
                    cadenaDeConfiguracion = char(cadenaDeConfiguracion); 
                    if contains(cadenaDeConfiguracion,nuevaCadenaDeConfiguracion)
                        A = antiguaCadenaDeConfiguracion;
                        obj.escribirComandoConCR(obj.dispositivoSerial,[obj.comando_solicitarConfiguracionDeControl uint8(antiguaCadenaDeConfiguracion)]);
                        obj.leerRespuesta(obj.dispositivoSerial);
                    else
                        A = [];
                    end
                end
            end
            if isempty(antiguaCadenaDeConfiguracion)
                disp ('No se encontró dispositivo FASTRAK');
            else
                disp (['Dispositivo FASTRAK encontrado en puerto ',obj.puerto]);
                disp(strtrim(char(A)));

                delete(obj.dispositivoSerial);

                puerto = obj.puerto;
                sensores = 1;

            end
        end
    end
end

