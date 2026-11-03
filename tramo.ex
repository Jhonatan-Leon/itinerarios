defmodule Tramo do
  defstruct [:origen, :destino, :minutos, :costo, :linea]

  def parse({linea, texto}) do

    case String.split(String.trim(texto), ",") do
    # El String.trim limpia el texto de los espacios en blanco - El split convierte los datos en lista cada que encuentra una coma
      [origen, destino, minutos, costo] ->
        origen = String.trim(origen)
        destino = String.trim(destino)

        # with va revisando cada condicion en orden, si alguna falla devuelve ese error y no sigue
        with :ok <- centro(origen, "origen"),
             :ok <- centro(destino, "destino"),
             {:ok, minutos} <- entero_positivo(minutos, "minutos"),
             {:ok, costo} <- entero_positivo(costo, "costo") do
          {:ok, %Tramo{origen: origen, destino: destino, minutos: minutos, costo: costo, linea: linea}}
        end
      _ ->
        {:error, "Se esperaban 4 campos: Origen, Destino, Minutos, Costo"}
      end
    end

  # El nombre del centro no puede venir vacio
  defp centro("", campo), do: {:error, "El #{campo} esta vacio"}
  defp centro(_, _campo), do: :ok

  # Integer.parse devuelve {numero, lo_que_sobra}, si sobra algo (como en "5.5" o "8abc") no es un entero
  defp entero_positivo(texto, campo) do
    case Integer.parse(String.trim(texto)) do
      {numero, ""} when numero > 0 -> {:ok, numero}
      {_numero, ""} -> {:error, "El campo #{campo} debe ser mayor que 0: #{texto}"}
      _ -> {:error, "El campo #{campo} debe ser un numero entero: #{texto}"}
    end
  end
end
