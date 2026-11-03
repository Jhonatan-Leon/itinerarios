defmodule Consulta do
  defstruct [:origen, :destino, :linea]

  # igual que Tramo.parse realmente 
  def parse({linea, texto}) do
    case String.split(texto, ",") do
      [origen, destino] ->
        origen = String.trim(origen)
        destino = String.trim(destino)

        if origen == "" or destino == "" do
          {:error, "El origen y el destino no pueden estar vacios"}
        else
          {:ok, %Consulta{origen: origen, destino: destino, linea: linea}}
        end

      _ ->
        {:error, "Se esperaban 2 campos: Origen, Destino"}
    end
  end

  # Revisa que el origen y el destino de cada consulta existan en la red.
  # Recibe los tramos YA depurados. Devuelve {buenas, malas}, donde cada mala es {consulta, motivo}
  def validar(consultas, tramos), do: validar(consultas, centros(tramos, %{}), [], [])

  defp validar([], _centros, buenas, malas), do: {invertir(buenas), invertir(malas)} # ya no quedan consultas por revisar

  defp validar([c | resto], centros, buenas, malas) do
    case faltantes(c, centros) do
      [] -> # los dos centros existen, la consulta pasa a la busqueda
        validar(resto, centros, [c | buenas], malas)

      [centro] ->
        validar(resto, centros, buenas, [{c, "el centro #{centro} no existe en la red"} | malas])

      [centro1, centro2] ->
        validar(resto, centros, buenas, [{c, "los centros #{centro1} y #{centro2} no existen en la red"} | malas])
    end
  end

  # Lista los centros de la consulta que no estan en la libreta de centros
  defp faltantes(c, centros) do
    origen = if Map.has_key?(centros, c.origen), do: [], else: [c.origen]
    destino = if Map.has_key?(centros, c.destino) or c.destino == c.origen, do: [], else: [c.destino]
    origen ++ destino
  end

  # Recorre los tramos y anota en la libreta cada origen y cada destino que aparece
  defp centros([], libreta), do: libreta

  defp centros([t | resto], libreta) do
    libreta = libreta |> Map.put(t.origen, true) |> Map.put(t.destino, true)
    centros(resto, libreta)
  end

  defp invertir(lista), do: invertir(lista, [])
  defp invertir([], acumulado), do: acumulado
  defp invertir([x | resto], acumulado), do: invertir(resto, [x | acumulado])
end
