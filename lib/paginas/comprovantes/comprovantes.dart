import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_money/modelos/comprovante.dart'; //
import 'package:flutter_money/modelos/despesa.dart'; //
import 'package:flutter_money/servicos/banco_dados.dart'; //
import 'package:path_provider/path_provider.dart'; //
import 'package:path/path.dart' as p; //
import 'package:image_picker/image_picker.dart'; //

class ComprovantesPage extends StatefulWidget {
  const ComprovantesPage({super.key});

  @override
  State<ComprovantesPage> createState() => _ComprovantesPageState();
}

class _ComprovantesPageState extends State<ComprovantesPage> {
  List<Comprovante> _comprovantes = []; //
  bool _isLoading = true; //
  final ImagePicker _picker = ImagePicker(); //

  @override
  void initState() {
    super.initState(); //
    _carregarComprovantes(); //
  }

  Future<void> _carregarComprovantes() async {
    setState(() {
      //
      _isLoading = true; //
    });
    try {
      final comprovantes = await BancoDados.instancia.listarComprovantes(); //
      setState(() {
        //
        _comprovantes = comprovantes; //
        _isLoading = false; //
      });
    } catch (e) {
      print('Erro ao carregar comprovantes: $e'); //
      setState(() {
        //
        _isLoading = false; //
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar comprovantes: $e')), //
      );
    }
  }

  Future<void> _tirarFotoOuEscolherGaleria(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source); //

      if (pickedFile != null) {
        //
        final File imagemTemporaria = File(pickedFile.path); //

        final appDir = await getApplicationDocumentsDirectory(); //
        final fileName = p.basename(pickedFile.path); //
        final caminhoPermanente = p.join(appDir.path, fileName); //

        if (!await appDir.exists()) {
          //
          await appDir.create(recursive: true); //
        }

        final File novaImagem = await imagemTemporaria.copy(
          caminhoPermanente,
        ); //

        _mostrarOpcoesComprovante(novaImagem.path); //
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma imagem selecionada.')), //
        );
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e'); //
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao acessar câmera/galeria: $e')), //
      );
    }
  }

  Future<void> _mostrarOpcoesComprovante(String caminhoArquivo) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Comprovante Capturado'), //
          content: Column(
            mainAxisSize: MainAxisSize.min, //
            children: [
              Image.file(
                File(caminhoArquivo), //
                width: 150, //
                height: 150, //
                fit: BoxFit.cover, //
                errorBuilder: (context, error, stackTrace) {
                  //
                  return const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.red, //
                  );
                },
              ),
              const SizedBox(height: 20), //
              ElevatedButton(
                onPressed: () async {
                  //
                  Navigator.of(context).pop(); //
                  await _vincularComprovante(caminhoArquivo); //
                },
                child: const Text('Vincular à uma despesa'), //
              ),
              const SizedBox(height: 10), //
              OutlinedButton(
                onPressed: () async {
                  //
                  Navigator.of(context).pop(); //
                  final novoComprovante = Comprovante(
                    caminhoArquivo: caminhoArquivo,
                    dataCaptura: DateTime.now(),
                    descricao: 'Comprovante avulso',
                  ); //
                  await BancoDados.instancia.inserirComprovante(
                    novoComprovante,
                  ); //
                  _carregarComprovantes(); //
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comprovante salvo como avulso!'),
                    ),
                  );
                },
                child: const Text('Salvar como avulso'), //
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _vincularComprovante(String caminhoArquivo) async {
    final despesas = await BancoDados.instancia.listarDespesas(); //

    if (despesas.isEmpty) {
      //
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma despesa encontrada para vincular.'),
        ),
      );
      return;
    }

    Despesa? despesaSelecionada = await showDialog<Despesa>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vincular Comprovante à Despesa'), //
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, //
              children: despesas.map((despesa) {
                //
                return ListTile(
                  title: Text(
                    '${despesa.nome ?? despesa.descricao} - R\$ ${despesa.valor.toStringAsFixed(2).replaceAll('.', ',')}', //
                  ),
                  onTap: () {
                    //
                    Navigator.of(context).pop(despesa); //
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (despesaSelecionada != null) {
      //
      final novoComprovante = Comprovante(
        caminhoArquivo: caminhoArquivo, //
        dataCaptura: DateTime.now(), //
        idDespesaVinculada: despesaSelecionada.id, //
        descricao: despesaSelecionada.nome ?? despesaSelecionada.descricao, //
      );

      try {
        await BancoDados.instancia.inserirComprovante(novoComprovante); //
        _carregarComprovantes(); //
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprovante vinculado com sucesso!'),
          ), //
        );
      } catch (e) {
        print('Erro ao vincular comprovante: $e'); //
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao vincular comprovante: $e')), //
        );
      }
    }
  }

  void _abrirImagemComprovante(Comprovante comprovante) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(comprovante.descricao ?? 'Comprovante'), //
          content: Column(
            mainAxisSize: MainAxisSize.min, //
            children: [
              Image.file(
                File(comprovante.caminhoArquivo), //
                width: 200, //
                height: 200, //
                fit: BoxFit.contain, //
                errorBuilder: (context, error, stackTrace) {
                  //
                  return const Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.red, //
                  );
                },
              ),
              const SizedBox(height: 10), //
              Text(
                'Data: ${comprovante.dataCaptura.toLocal().toString().split(' ')[0]}', //
              ),
              if (comprovante.idDespesaVinculada != null) //
                Text(
                  'Vinculado à Despesa ID: ${comprovante.idDespesaVinculada}', //
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), //
              child: const Text('Fechar'), //
            ),
            TextButton(
              onPressed: () async {
                //
                try {
                  final fileToRemove = File(comprovante.caminhoArquivo); //
                  if (await fileToRemove.exists()) {
                    //
                    await fileToRemove.delete(); //
                    print(
                      'Arquivo de comprovante removido: ${comprovante.caminhoArquivo}', //
                    );
                  }
                } catch (e) {
                  print('Erro ao remover arquivo de comprovante: $e'); //
                }

                await BancoDados.instancia.removerComprovante(
                  comprovante.id!,
                ); //
                _carregarComprovantes(); //
                Navigator.of(context).pop(); //
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comprovante removido!')), //
                );
              },
              child: const Text('Remover'), //
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Comprovantes',
          style: TextStyle(
            color: Colors.black, // Título preto
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) //
          : _comprovantes
                .isEmpty //
          ? const Center(child: Text('Nenhum comprovante adicionado ainda.')) //
          : GridView.builder(
              padding: const EdgeInsets.all(8.0), //
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, //
                crossAxisSpacing: 8.0, //
                mainAxisSpacing: 8.0, //
              ),
              itemCount: _comprovantes.length, //
              itemBuilder: (context, index) {
                //
                final comprovante = _comprovantes[index]; //
                return GestureDetector(
                  onTap: () => _abrirImagemComprovante(comprovante), //
                  child: Card(
                    clipBehavior: Clip.antiAlias, //
                    child: Stack(
                      fit: StackFit.expand, //
                      children: [
                        Image.file(
                          File(comprovante.caminhoArquivo), //
                          fit: BoxFit.cover, //
                          errorBuilder: (context, error, stackTrace) {
                            //
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.red, //
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54, //
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                            ), //
                            child: Text(
                              comprovante.descricao ?? 'Comprovante', //
                              textAlign: TextAlign.center, //
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              maxLines: 1, //
                              overflow: TextOverflow.ellipsis, //
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min, //
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt), //
                  title: const Text('Tirar Foto'), //
                  onTap: () {
                    //
                    Navigator.of(context).pop(); //
                    _tirarFotoOuEscolherGaleria(ImageSource.camera); //
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library), //
                  title: const Text('Escolher da Galeria'), //
                  onTap: () {
                    //
                    Navigator.of(context).pop(); //
                    _tirarFotoOuEscolherGaleria(ImageSource.gallery); //
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add_a_photo), //
      ),
    );
  }
}
