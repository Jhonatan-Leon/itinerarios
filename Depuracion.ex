defmodule Depuracion do
  def depurar(tramos), do: depurar(tramos, %{}, [], []) #Esta es la primera iteracion, la funcion publica a la que se puede
  #acceder desde otros lados. Los tramos corresponden a la pila de tarjetas a revisar, %{} es la libreta, [] es la caja de buenos
  #y el ultimo [] es la caja de malos

  defp depurar([], _vistos, buenos, descartes), #Este es el caso final cuando se cumple que la pila este vacia, que ya no haya nada mas
    do: {invertir(buenos), invertir(descartes)} #Que revisar

  defp depurar([t | resto], vistos, buenos, descartes) do #Cuando aun hay que revisar elementos de la pila se ejecuta este caso de trabajo
    cond do
      t.origen == t.destino -> #pregunta que si el tramo sale y llega al mismo lugar 
        depurar(resto, vistos, buenos, [{t, "bucle: sale y llega al mismo centro"} | descartes]) #En caso de un bucle sigue con las otras tarjetas y lo manda a descartes

      Map.has_key?(vistos, {t.origen, t.destino}) -> #aca pregunta que si ya anoto la pareja en la libreta
        depurar(resto, vistos, buenos, [{t, "tramo repetido en la misma dirección"} | descartes])

      true -> # En cualquier otro caso el tramo esta bien :)
        depurar(resto, Map.put(vistos, {t.origen, t.destino}, true), [t | buenos], descartes) #mete el tramo en buenos, anota la pareja en la libreta y sigue con el resto
    end
  end

  # aca cree la funcion de invertir teniendo en cuenta que añado cada tramo al inicio de las listas, esto hace que quede todo al reves y pues se usa esto para invertirlo
  # (todo seria mucho mas facil con un simple enum.reverse)
  defp invertir(lista), do: invertir(lista, [])
  defp invertir([], acumulado), do: acumulado
  defp invertir([x | resto], acumulado), do: invertir(resto, [x | acumulado])
end
