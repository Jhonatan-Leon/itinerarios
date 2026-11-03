defmodule Tramo do
  defstruct [:origen, :destino, :minutos, :costo, :linea]

  def parse({linea, texto}) do

    case String.split(String.trim(texto), ",") do
    # El String.trim limpia el texto de los espacios en blanco - El split convierte los datos en lista cada que encuentra una coma
      [origen, destino, minutos, costo] ->
        {:ok, %Tramo{origen: origen, destino: destino, minutos: String.to_integer(minutos), costo: String.to_integer(costo), linea: linea}}
      _ ->
        {:error, "Se esperaban 4 campos: Origen, Destino, Minutos, Costo"}
      end
    end
end
