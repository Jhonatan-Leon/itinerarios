defmodule Utilidades do
  @moduledoc """
  Funciones recursivas pequeñas que usan varios módulos del proyecto.
  Están aquí para no repetirlas en cada archivo.
  """

  @doc """
  Devuelve la lista en orden inverso.

  Sirve porque al acumular elementos al inicio de una lista queda al revés.

  ## Parámetros
    - lista: la lista a voltear.
  """
  def invertir(lista), do: invertir(lista, [])

  defp invertir([], acc), do: acc
  defp invertir([x | resto], acc), do: invertir(resto, [x | acc])

  @doc """
  Indica si un elemento está en la lista.

  Se usa para saber si un centro ya fue visitado en el itinerario actual.

  ## Parámetros
    - elemento: lo que se busca.
    - lista: donde se busca.
  """
  def pertenece?(_elemento, []), do: false
  def pertenece?(x, [x | _resto]), do: true
  def pertenece?(x, [_otro | resto]), do: pertenece?(x, resto)
end
