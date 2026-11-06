# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia

defmodule Alcance do
  @moduledoc """
  Stream infinito de conjuntos de centros alcanzables.

  Paso 0: solo el origen. Cada paso siguiente añade los destinos de los
  tramos que salen de los centros ya alcanzados.

  Trabaja sobre el grafo creado con Grafo.construir/1, que es un mapa
  centro => lista de %Tramo{} que salen de ese centro.
  """

  @doc """
  Stream INFINITO de estados (cada estado es un MapSet de centros).
  Nunca termina por sí solo: quien lo consume decide cuándo parar.

  ## Parámetros
    - origen: centro donde empieza la consulta.
    - grafo: mapa creado con Grafo.construir/1.

  """
  def estados(origen, grafo) do
    Stream.iterate(MapSet.new([origen]), fn alcanzados ->
      siguiente_estado(alcanzados, grafo)
    end)
  end

  @doc """
  Consume solo los pasos necesarios: emite {paso, estado} y se detiene en el
  primer estado igual al anterior (primer estado repetido consecutivo).

  Devuelve la lista de estados distintos con su número de paso.
  """
  def estados_distintos(origen, grafo) do
    origen
    |> estados(grafo)
    |> Stream.with_index()
    |> Stream.transform(nil, fn {estado, paso}, anterior ->
      if estado == anterior do
        {:halt, anterior}
      else
        {[{paso, estado}], estado}
      end
    end)
    |> Enum.to_list()
  end

  @doc """
  Analiza una consulta. Devuelve un mapa con:
    - pasos: lista de {paso, estado} distintos.
    - estabiliza_en: número del paso donde el estado deja de cambiar.
    - alcanzable: true si el destino está en el último estado.
  """
  def analizar(origen, destino, grafo) do
    pasos = estados_distintos(origen, grafo)
    {paso_final, estado_final} = List.last(pasos)

    %{
      pasos: pasos,
      estabiliza_en: paso_final,
      alcanzable: MapSet.member?(estado_final, destino)
    }
  end

  @doc """
  Líneas de texto (cada una termina en salto de línea) para alcance_centros.txt.
  """
  def a_lineas(origen, destino, resultado) do
    encabezado = ["=== #{origen} → #{destino} ===\n"]

    pasos =
      Enum.map(resultado.pasos, fn {paso, estado} ->
        "Paso #{paso}: {#{formatear(estado)}}\n"
      end)

    estabiliza =
      "Se estabiliza en el paso #{resultado.estabiliza_en} " <>
        "(el paso #{resultado.estabiliza_en + 1} repite el estado)\n"

    alcance =
      if resultado.alcanzable do
        "Destino alcanzable\n"
      else
        "sin itinerarios\n"
      end

    encabezado ++ pasos ++ [estabiliza, alcance, "\n"]
  end

  # Un paso: al conjunto actual se le añaden los destinos de sus tramos.
  defp siguiente_estado(alcanzados, grafo) do
    Enum.reduce(alcanzados, alcanzados, fn centro, acc ->
      grafo
      |> Map.get(centro, [])
      |> Enum.reduce(acc, fn tramo, conjunto -> MapSet.put(conjunto, tramo.destino) end)
    end)
  end

  defp formatear(estado) do
    estado
    |> MapSet.to_list()
    |> Enum.sort()
    |> Enum.join(", ")
  end
end
