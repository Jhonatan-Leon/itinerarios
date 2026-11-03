defmodule Lector do
  def leer_tramos(ruta) do
    if File.exists?(ruta) do
      {buenos, malos} = ruta
      |> File.stream!() #procede a leer linea por linea
      |> Stream.with_index(1) # Los enumera
      |> Stream.map(fn {texto, num} -> {num, String.trim(texto)} end)
      |> Stream.reject(fn {_num, texto} -> ignorar?(texto) end) #quita vacios y comentarios
      |> Stream.map(fn {num, texto} -> {num, texto, Tramo.parse({num, texto})} end) # Convierte con el parse
      |> Enum.split_with(fn {_, _, resultado} -> match?({:ok, _}, resultado) end) # aqui ejecuta todo

      tramos = Enum.map(buenos, fn {_, _, {:ok, tramo}} -> tramo end)
      errores = Enum.map(malos, fn {num, texto, {:error, motivo}} -> {num, texto, motivo} end)

      {:ok, tramos, errores}
    else
      {:error, "no se encontro el archivo requerido: #{ruta}"}
    end
  end

  # Igual que leer_tramos pero cada linea se convierte con Consulta.parse
  def leer_consultas(ruta) do
    if File.exists?(ruta) do
      {buenas, malas} = ruta
      |> File.stream!()
      |> Stream.with_index(1)
      |> Stream.map(fn {texto, num} -> {num, String.trim(texto)} end)
      |> Stream.reject(fn {_num, texto} -> ignorar?(texto) end)
      |> Stream.map(fn {num, texto} -> {num, texto, Consulta.parse({num, texto})} end)
      |> Enum.split_with(fn {_, _, resultado} -> match?({:ok, _}, resultado) end)

      consultas = Enum.map(buenas, fn {_, _, {:ok, consulta}} -> consulta end)
      errores = Enum.map(malas, fn {num, texto, {:error, motivo}} -> {num, texto, motivo} end)

      {:ok, consultas, errores}
    else
      {:error, "no se encontro el archivo requerido: #{ruta}"}
    end
  end

  defp ignorar?(""), do: true #ignora los vacios
  defp ignorar?("#" <> _), do: true # ignora los comentarios
  defp ignorar?(_), do: false # deja pasar todo lo demas
end


# BORRAR ESTO DESPUES, EJEMPLO DE COMO USAR

case Lector.leer_tramos("datos/tramos.csv") do
  {:ok, tramos, errores} ->
    # tramos va a la depuración
    IO.puts("Tramos válidos: #{length(tramos)}, con error: #{length(errores)}")

  {:error, mensaje} ->
    IO.puts(mensaje)   # avisa y no revienta
end
