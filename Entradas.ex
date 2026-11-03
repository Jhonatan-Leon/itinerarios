defmodule Entradas do
  # Esta es la funcion que se usa
  # Si falta algun archivo devuelve {:error, mensajes} con TODOS los que faltan
  def cargar(ruta_tramos \\ "datos/tramos.csv", ruta_consultas \\ "datos/consultas.txt") do
    case {Lector.leer_tramos(ruta_tramos), Lector.leer_consultas(ruta_consultas)} do
      {{:ok, tramos, errores_tramos}, {:ok, consultas, errores_consultas}} ->
        {tramos, descartes} = Depuracion.depurar(tramos) # primero se depura la red
        {consultas, consultas_invalidas} = Consulta.validar(consultas, tramos) # y con la red limpia se validan las consultas

        {:ok,
         %{
           tramos: tramos, # para la busqueda
           consultas: consultas, # para la busqueda 
           errores_tramos: errores_tramos, # {linea, texto, motivo} para errores_tramos.txt
           descartes: descartes, # {tramo, motivo} para depuracion_tramos.txt
           errores_consultas: errores_consultas, # {linea, texto, motivo} consultas mal escritas
           consultas_invalidas: consultas_invalidas # {consulta, motivo} centros que no existen
         }}

      {{:error, mensaje1}, {:error, mensaje2}} -> {:error, [mensaje1, mensaje2]}
      {{:error, mensaje}, _} -> {:error, [mensaje]}
      {_, {:error, mensaje}} -> {:error, [mensaje]}
    end
  end
end
