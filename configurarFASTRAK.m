%% Autor: Francisco Marcano. 2023.
%% Ejemplo: configurarFASTRACK('COM37')
function configurarFASTRAK(puerto,bauds)
    s = serialport(puerto,'BaudRate',bauds);

end

