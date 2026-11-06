# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia

Code.require_file("tramo.ex", __DIR__)
Code.require_file("Consulta.ex", __DIR__)
Code.require_file("Lector.ex", __DIR__)
Code.require_file("Depuracion.ex", __DIR__)
Code.require_file("Entradas.ex", __DIR__)
Code.require_file("grafo.exs", __DIR__)
Code.require_file("Itinerario.exs", __DIR__)
Code.require_file("Utilidades.exs", __DIR__)
Code.require_file("Busqueda.exs", __DIR__)
Code.require_file("Optimos.exs", __DIR__)
Code.require_file("Alcance.exs", __DIR__)

defmodule Flujo do
  @moduledoc """
  Problema 1: une la lectura, la depuración, el Stream de alcance, la búsqueda
  de itinerarios y los óptimos, y escribe las salidas por flujo.

  Orden de trabajo:
    1. Entradas.cargar/2 lee (Streams perezosos) y depura la red.
    2. Grafo.construir/1 arma el grafo con los tramos depurados.
    3. Por cada consulta, en el orden del archivo:
       a. Alcance.analizar/3 consume el Stream infinito de centros alcanzables.
       b. Si el destino NO es alcanzable: "sin itinerarios", sin búsqueda.
       c. Si lo es: Busqueda.itinerarios/3 y los óptimos de Optimos.
    4. Cada bloque se escribe apenas se calcula; en pantalla se muestra el
       total de itinerarios por consulta.

  Cada carpeta de datos guarda sus salidas en Salidas/<nombre>:
  itinerarios.txt, alcance_centros.txt, errores_tramos.txt,
  depuracion_tramos.txt y errores_consultas.txt.
  """

  @datos Path.join(__DIR__, "datos")
  @salidas Path.join(__DIR__, "Salidas")

  @doc """
  Procesa una carpeta con tramos.csv y consultas.txt.

  Devuelve {:ok, resumen} o {:error, mensajes} (por ejemplo, si falta un
  archivo), sin lanzar excepciones.

  ## Parámetros
    - carpeta_datos: carpeta de entrada (por defecto, datos/ junto a este archivo).

  """
  def ejecutar(carpeta_datos \\ @datos) do
    ruta_tramos = Path.join(carpeta_datos, "tramos.csv")
    ruta_consultas = Path.join(carpeta_datos, "consultas.txt")

    case Entradas.cargar(ruta_tramos, ruta_consultas) do
      {:ok, entradas} ->
        procesar(entradas, carpeta_salida(carpeta_datos))

      {:error, mensajes} ->
        Enum.each(mensajes, fn mensaje -> IO.puts(:standard_error, mensaje) end)
        {:error, mensajes}
    end
  end

  defp procesar(entradas, carpeta) do
    with :ok <- File.mkdir_p(carpeta),
         {:ok, itinerarios} <- abrir(Path.join(carpeta, "itinerarios.txt")),
         {:ok, alcance} <- abrir(Path.join(carpeta, "alcance_centros.txt")) do
      # Listas pequeñas ya calculadas: se escriben línea por línea.
      guardar(Path.join(carpeta, "errores_tramos.txt"), entradas.errores_tramos, &linea_error/1)
      guardar(Path.join(carpeta, "depuracion_tramos.txt"), entradas.descartes, &linea_descarte/1)

      guardar(
        Path.join(carpeta, "errores_consultas.txt"),
        entradas.errores_consultas,
        &linea_error/1
      )

      grafo = Grafo.construir(entradas.tramos)

      resumen =
        entradas.consultas
        |> ordenar_consultas(entradas.consultas_invalidas)
        |> Enum.map(fn consulta -> procesar_consulta(consulta, grafo, itinerarios, alcance) end)

      File.close(itinerarios)
      File.close(alcance)

      mostrar_resumen(resumen, entradas, carpeta)
      {:ok, resumen}
    else
      {:error, motivo} ->
        IO.puts(:standard_error, "No se pudo completar el proceso: #{motivo}")
        {:error, [motivo]}
    end
  end

  # Datos de prueba en "datos" -> Salidas/ejemplos; los demás usan su nombre.
  defp carpeta_salida(carpeta_datos) do
    nombre =
      case Path.basename(Path.expand(carpeta_datos)) do
        "datos" -> "ejemplos"
        otro -> otro
      end

    Path.join(@salidas, nombre)
  end

  # Crea o reemplaza un archivo de salida. Un error se devuelve como tupla.
  defp abrir(ruta) do
    case File.open(ruta, [:write, :utf8]) do
      {:ok, archivo} -> {:ok, archivo}
      {:error, razon} -> {:error, "no se pudo crear #{ruta}: #{:file.format_error(razon)}"}
    end
  end

  # Escribe cada elemento como una línea, a medida que el Stream la produce.
  defp guardar(ruta, elementos, formatear) do
    elementos
    |> Stream.map(formatear)
    |> Enum.into(File.stream!(ruta))
  end

  defp linea_error({linea, texto, motivo}), do: "Línea #{linea}: #{texto} -> #{motivo}\n"

  defp linea_descarte({tramo, motivo}) do
    contenido = "#{tramo.origen},#{tramo.destino},#{tramo.minutos},#{tramo.costo}"
    "Línea #{tramo.linea}: #{contenido} -> #{motivo}\n"
  end

  # Mezcla consultas válidas e inválidas y las deja en el orden del archivo.
  defp ordenar_consultas(validas, invalidas) do
    de_validas = Enum.map(validas, fn c -> {c.linea, {:valida, c}} end)
    de_invalidas = Enum.map(invalidas, fn {c, motivo} -> {c.linea, {:invalida, c, motivo}} end)

    (de_validas ++ de_invalidas)
    |> Enum.sort_by(fn {linea, _consulta} -> linea end)
    |> Enum.map(fn {_linea, consulta} -> consulta end)
  end

  # Un centro no existe: se informa y NO se inicia la búsqueda.
  defp procesar_consulta({:invalida, consulta, motivo}, _grafo, itinerarios, alcance) do
    escribir(itinerarios, [titulo(consulta), "No se inicia la búsqueda: #{motivo}\n", "\n"])
    escribir(alcance, [titulo(consulta), "No se calcula el alcance: #{motivo}\n", "\n"])
    {consulta, {:invalida, motivo}}
  end

  defp procesar_consulta({:valida, consulta}, grafo, itinerarios, alcance) do
    analisis = Alcance.analizar(consulta.origen, consulta.destino, grafo)
    escribir(alcance, Alcance.a_lineas(consulta.origen, consulta.destino, analisis))

    if analisis.alcanzable do
      lista = Busqueda.itinerarios(grafo, consulta.origen, consulta.destino)
      escribir(itinerarios, lineas_itinerarios(consulta, lista))
      {consulta, length(lista)}
    else
      # Destino no alcanzable: se omite la búsqueda exhaustiva.
      escribir(itinerarios, [titulo(consulta), "sin itinerarios\n", "Total: 0 itinerarios\n", "\n"])
      {consulta, 0}
    end
  end

  defp escribir(archivo, lineas) do
    Enum.each(lineas, fn linea -> IO.write(archivo, linea) end)
  end

  defp titulo(consulta), do: "=== #{consulta.origen} → #{consulta.destino} ===\n"

  # Bloque de una consulta: itinerarios numerados, total y los tres óptimos.
  defp lineas_itinerarios(consulta, lista) do
    numerados = Optimos.numerar(lista)
    detalle = Enum.map(numerados, fn {numero, it} -> linea_itinerario(numero, it) end)
    total = length(lista)

    [titulo(consulta)] ++
      detalle ++
      [
        "Total: #{total} #{plural(total)}\n",
        "Menos tramos: #{numeros(Optimos.menos_tramos(numerados))}\n",
        "Menor tiempo: #{numeros(Optimos.menor_tiempo(numerados))}\n",
        "Menor costo: #{numeros(Optimos.menor_costo(numerados))}\n",
        "\n"
      ]
  end

  defp linea_itinerario(numero, itinerario) do
    recorrido = Enum.join(itinerario.centros, " → ")
    tramos = length(itinerario.centros) - 1

    "Itinerario #{numero}: #{recorrido} | tramos: #{tramos} | " <>
      "#{itinerario.minutos} min | costo: #{itinerario.costo}\n"
  end

  defp numeros(lista), do: Enum.join(lista, ", ")

  defp plural(1), do: "itinerario"
  defp plural(_total), do: "itinerarios"

  defp mostrar_resumen(resumen, entradas, carpeta) do
    IO.puts("Tramos con error de formato o datos: #{length(entradas.errores_tramos)}")
    IO.puts("Tramos descartados en la depuración: #{length(entradas.descartes)}")
    IO.puts("Consultas con error de formato: #{length(entradas.errores_consultas)}")
    IO.puts("")

    if resumen == [] do
      IO.puts("No hay consultas para procesar.")
    else
      Enum.each(resumen, &mostrar_consulta/1)
    end

    IO.puts("\nSalidas guardadas en: #{carpeta}")
  end

  defp mostrar_consulta({consulta, {:invalida, motivo}}) do
    IO.puts("#{consulta.origen} → #{consulta.destino}: no se buscó (#{motivo})")
  end

  defp mostrar_consulta({consulta, total}) do
    IO.puts("#{consulta.origen} → #{consulta.destino}: #{total} #{plural(total)}")
  end
end

case System.argv() do
  [carpeta | _] -> Flujo.ejecutar(carpeta)
  [] -> Flujo.ejecutar()
end
