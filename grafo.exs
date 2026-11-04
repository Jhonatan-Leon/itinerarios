Code.require_file("Itinerarios.exs", __DIR__)
Code.require_file("Utilidades.exs", __DIR__)

defmodule Busqueda do
  @moduledoc """
  Busca todos los itinerarios simples entre dos centros.

  Un itinerario simple no repite centros y respeta la dirección de los
  tramos. La búsqueda es recursiva: desde el centro actual prueba cada tramo
  que sale de él y se detiene al llegar al destino.
  """

  @doc """
  Devuelve todos los itinerarios posibles de origen a destino.

  Si no hay ninguna ruta devuelve una lista vacía.

  ## Parámetros
    - grafo: mapa creado con Grafo.construir/1.
    - origen: centro donde empieza el recorrido.
    - destino: centro donde debe terminar.

  """
  def itinerarios(grafo, origen, destino),
    do: explorar(grafo, origen, destino, [origen], 0, 0)

  #Se llegó al destino. Se arma el itinerario con lo acumulado.
  # Un camino simple no puede pasar por el destino y volver.
  defp explorar(_grafo, destino, destino, camino, minutos, costo) do
    [%Itinerario{centros: Utilidades.invertir(camino), minutos: minutos, costo: costo}]
  end

  # Se prueban los tramos que salen del centro actual
  defp explorar(grafo, actual, destino, camino, minutos, costo) do
    probar(Map.get(grafo, actual, []), grafo, destino, camino, minutos, costo)
  end

  # No quedan tramos por probar desde este centro
  defp probar([], _grafo, _destino, _camino, _minutos, _costo), do: []

  # Prueba un tramo y luego sigue con el resto de tramos del mismo centro
  defp probar([t | resto], grafo, destino, camino, minutos, costo) do
    hallados =
      if Utilidades.pertenece?(t.destino, camino) do
        # el centro ya está en este itinerario: se descarta
        []
      else
        explorar(grafo, t.destino, destino, [t.destino | camino],
                 minutos + t.minutos, costo + t.costo)
      end

    hallados ++ probar(resto, grafo, destino, camino, minutos, costo)
  end
end
