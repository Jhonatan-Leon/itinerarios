defmodule Grafo do
  @moduledoc """
  Convierte la lista de tramos en un grafo para poder buscar rápidamente.

  El grafo es un mapa: cada clave es un centro de origen y su valor es la
  lista de tramos que salen de ese centro.
  """

  @doc """
  Agrupa los tramos por centro de origen, conservando el orden de llegada.

  ## Parámetros
    - tramos: lista de %Tramo{} ya depurados.

  """
  def construir(tramos), do: construir(tramos, %{})

  # No quedan tramos, se devuelve el grafo armado
  defp construir([], grafo), do: grafo

  # Se agrega el tramo a la lista de su origen y se sigue
  defp construir([t | resto], grafo) do
    grafo = Map.update(grafo, t.origen, [t], fn lista -> lista ++ [t] end)
    construir(resto, grafo)
  end
end
