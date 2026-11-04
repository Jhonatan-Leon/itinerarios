Code.require_file("Itinerario.exs", __DIR__)

defmodule Optimos do
  @moduledoc """
  Encuentra los itinerarios óptimos según un criterio: tramos, tiempo o costo.

  Trabaja con itinerarios numerados y reporta el número de TODOS los que
  empatan en el mejor valor.
  """

  @doc """
  Le asigna un número a cada itinerario, empezando en 1.

  La salida muestra "Itinerario 1", "Itinerario 2"... y los óptimos se
  reportan por ese número.

  ## Parámetros
    - lista: lista de %Itinerario{} en el orden en que se encontraron.

  """
  def numerar(lista), do: numerar(lista, 1)

  defp numerar([], _n), do: []
  defp numerar([x | resto], n), do: [{n, x} | numerar(resto, n + 1)]

  @doc """
  Números de los itinerarios con menos tramos (todos los empates).

  ## Parámetros
    - numerados: lista {numero, %Itinerario{}} creada con numerar/1.


  """
  def menos_tramos(numerados),
    do: minimos(numerados, fn it -> length(it.centros) - 1 end)

  @doc """
  Números de los itinerarios con menor tiempo (todos los empates).

  ## Parámetros
    - numerados: lista {numero, %Itinerario{}} creada con numerar/1.

  """
  def menor_tiempo(numerados), do: minimos(numerados, fn it -> it.minutos end)

  @doc """
  Números de los itinerarios con menor costo (todos los empates).

  ## Parámetros
    - numerados: lista {numero, %Itinerario{}} creada con numerar/1.

  """
  def menor_costo(numerados), do: minimos(numerados, fn it -> it.costo end)

  # Motor común de los tres criterios: `f` dice qué valor minimizar
  defp minimos([], _f), do: []
  defp minimos([{n, it} | resto], f), do: minimos(resto, f.(it), [n], f)

  # Caso base: se revisaron todos, se devuelven los números en orden
  defp minimos([], _mejor, acc, _f), do: Utilidades.invertir(acc)

  # Compara cada itinerario contra el mejor valor visto hasta ahora
  defp minimos([{n, it} | resto], mejor, acc, f) do
    valor = f.(it)

    #Algoritmo de comparación: es como una burbuja que
    #recorre la lista y va guardando los mejores valores y sus números
    cond do
      # Se descartan los anteriores
      valor < mejor -> minimos(resto, valor, [n], f)
      #Se conserva junto a los demás
      valor == mejor -> minimos(resto, mejor, [n | acc], f)
      # Se ignora
      true -> minimos(resto, mejor, acc, f)
    end
  end
end
