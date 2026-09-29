import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// A tela que terá um estado mutável (o visor muda conforme o usuário digita)
class CalculadoraPage extends StatefulWidget {
  const CalculadoraPage({super.key});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

// A classe que contém o estado e a lógica da calculadora
class _CalculadoraPageState extends State<CalculadoraPage> {
  // Controla o foco para capturar as teclas do teclado físico
  final FocusNode _focusNode = FocusNode();

  // ----- Variáveis de estado -----
  String _expressao = ''; // Linha de cima: a expressão (ex.: "12 + 5 ")
  String _display = '0'; // Linha de baixo: número atual ou resultado
  bool _reiniciarNumero = false; // O próximo dígito começa um novo número
  bool _mostrouResultado = false; // Acabou de mostrar o resultado do "="

  // Libera o FocusNode quando o widget é removido da tela (ciclo de vida: dispose)
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Recebe cada evento do teclado físico e o converte em uma "tecla" da calculadora
  void _aoTeclar(KeyEvent evento) {
    // Só reagimos quando a tecla é pressionada (e não solta)
    if (evento is! KeyDownEvent) {
      return;
    }

    final String? tecla = _mapearTeclaFisica(evento);
    if (tecla != null) {
      _pressionar(tecla);
    }
  }

  // Traduz a tecla do teclado físico para o símbolo usado na calculadora
  String? _mapearTeclaFisica(KeyEvent evento) {
    final String? caractere = evento.character;

    // Dígitos e símbolos digitados diretamente
    if (caractere != null) {
      if (RegExp(r'[0-9]').hasMatch(caractere)) {
        return caractere;
      }
      if (caractere == '.' || caractere == ',') {
        return '.';
      }
      if (caractere == '+') {
        return '+';
      }
      if (caractere == '-') {
        return '-';
      }
      if (caractere == '*') {
        return '×';
      }
      if (caractere == '/') {
        return '÷';
      }
      if (caractere == '=') {
        return '=';
      }
    }

    // Teclas especiais
    final LogicalKeyboardKey tecla = evento.logicalKey;
    if (tecla == LogicalKeyboardKey.enter ||
        tecla == LogicalKeyboardKey.numpadEnter) {
      return '=';
    }
    if (tecla == LogicalKeyboardKey.backspace) {
      return '⌫';
    }
    if (tecla == LogicalKeyboardKey.escape) {
      return 'C';
    }

    return null; // Tecla que não usamos
  }

  // Ponto central: decide o que fazer com a tecla (vinda do botão OU do teclado)
  void _pressionar(String tecla) {
    // setState avisa ao Flutter que o estado mudou e a interface deve ser redesenhada
    setState(() {
      if (RegExp(r'[0-9]').hasMatch(tecla)) {
        _aoDigitar(tecla);
      } else if (tecla == '.') {
        _aoAdicionarPonto();
      } else if (tecla == '+' || tecla == '-' || tecla == '×' || tecla == '÷') {
        _aoOperar(tecla);
      } else if (tecla == '=') {
        _aoIgual();
      } else if (tecla == 'C') {
        _limpar();
      } else if (tecla == '⌫') {
        _apagar();
      }
    });
  }

  // Adiciona um dígito ao número que está sendo digitado
  void _aoDigitar(String digito) {
    // Se acabou de mostrar um resultado, começa uma conta nova
    if (_mostrouResultado) {
      _expressao = '';
      _display = '0';
      _mostrouResultado = false;
    }

    if (_reiniciarNumero || _display == '0') {
      _display = digito;
      _reiniciarNumero = false;
    } else {
      _display += digito;
    }
  }

  // Adiciona a vírgula decimal (evitando duas vírgulas no mesmo número)
  void _aoAdicionarPonto() {
    if (_mostrouResultado) {
      _expressao = '';
      _display = '0';
      _mostrouResultado = false;
    }
    if (_reiniciarNumero) {
      _display = '0';
      _reiniciarNumero = false;
    }
    if (!_display.contains('.')) {
      _display += '.';
    }
  }

  // Guarda o número atual na expressão junto com a operação escolhida
  void _aoOperar(String operacao) {
    // Se o visor tem um erro, ignora a operação
    if (double.tryParse(_display) == null) {
      return;
    }

    // Se acabou de calcular, continua a conta a partir do resultado
    if (_mostrouResultado) {
      _expressao = '$_display $operacao ';
      _mostrouResultado = false;
      _reiniciarNumero = true;
      return;
    }

    if (_reiniciarNumero && _expressao.length >= 2) {
      // Usuário apertou dois operadores seguidos: troca o operador anterior
      _expressao = '${_expressao.substring(0, _expressao.length - 2)}$operacao ';
    } else {
      // Adiciona o número atual e o operador à expressão
      _expressao += '$_display $operacao ';
      _reiniciarNumero = true;
    }
  }

  // Calcula o resultado ao pressionar "="
  void _aoIgual() {
    // Sem expressão ou já mostrando resultado: não há o que calcular
    if (_expressao.isEmpty || _mostrouResultado) {
      return;
    }

    // Monta a expressão completa: parte confirmada + número atual
    final String expressaoCompleta = '$_expressao$_display';

    // Usamos try/catch para tratar a divisão por zero
    try {
      final double valor = _avaliar(expressaoCompleta);
      _expressao = '$expressaoCompleta ='; // Ex.: "12 + 5 ="
      _display = _formatar(valor);
    } on ArgumentError catch (e) {
      _expressao = '';
      _display = e.message;
    }

    _mostrouResultado = true;
    _reiniciarNumero = true;
  }

  // Avalia a expressão da esquerda para a direita (como uma calculadora simples)
  double _avaliar(String expressao) {
    // Separa a expressão em partes: ["12", "+", "5"]
    final List<String> partes = expressao.trim().split(RegExp(r'\s+'));
    double resultado = double.parse(partes[0]);

    // Percorre de dois em dois: operador e próximo número
    for (int i = 1; i < partes.length - 1; i += 2) {
      final String operacao = partes[i];
      final double numero = double.parse(partes[i + 1]);

      switch (operacao) {
        case '+':
          resultado += numero;
          break;
        case '-':
          resultado -= numero;
          break;
        case '×':
          resultado *= numero;
          break;
        case '÷':
          if (numero == 0) {
            throw ArgumentError('Erro: ÷ por 0');
          }
          resultado /= numero;
          break;
      } // switch
    }

    return resultado;
  }

  // Formata o resultado: mostra 5 em vez de 5.0 quando é inteiro
  String _formatar(double valor) {
    if (valor == valor.truncateToDouble()) {
      return valor.toInt().toString();
    }
    return valor.toString();
  }

  // Limpa tudo e volta ao estado inicial
  void _limpar() {
    _expressao = '';
    _display = '0';
    _reiniciarNumero = false;
    _mostrouResultado = false;
  }

  // Apaga o último dígito digitado
  void _apagar() {
    // Se estava mostrando um resultado, limpa tudo
    if (_mostrouResultado) {
      _limpar();
      return;
    }
    if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    // O KeyboardListener captura as teclas do teclado físico
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _aoTeclar,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calculadora'),
        ), // AppBar
        body: Column(
          children: <Widget>[
            // ----- Visor -----
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    // Linha de cima: a expressão que está sendo montada
                    Text(
                      _expressao,
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.grey[600],
                      ), // TextStyle
                    ), // Text
                    const SizedBox(height: 8),
                    // Linha de baixo: número atual ou resultado
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ), // TextStyle
                      ), // Text
                    ), // FittedBox
                  ], // <Widget>[]
                ), // Column
              ), // Container
            ), // Expanded
            // ----- Teclado numérico -----
            Expanded(
              flex: 5,
              child: Column(
                children: <Widget>[
                  _linha(<String>['C', '⌫', '÷', '×']),
                  _linha(<String>['7', '8', '9', '-']),
                  _linha(<String>['4', '5', '6', '+']),
                  _linha(<String>['1', '2', '3', '=']),
                  // Última linha: o 0 ocupa o dobro do espaço
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _tecla('0', flex: 3),
                        _tecla('.'),
                      ], // <Widget>[]
                    ), // Row
                  ), // Expanded
                ], // <Widget>[]
              ), // Column
            ), // Expanded
          ], // <Widget>[]
        ), // Column
      ), // Scaffold
    ); // KeyboardListener
  }

  // Cria uma linha de teclas do teclado
  Widget _linha(List<String> teclas) {
    return Expanded(
      child: Row(
        children: teclas.map((String t) => _tecla(t)).toList(),
      ), // Row
    ); // Expanded
  }

  // Cria um único botão (tecla) da calculadora
  Widget _tecla(String texto, {int flex = 1}) {
    // Define uma cor diferente para operações, "=" e "C"
    Color? cor;
    if (texto == '=') {
      cor = Colors.blue;
    } else if (texto == 'C' || texto == '⌫') {
      cor = Colors.redAccent;
    } else if (texto == '+' ||
        texto == '-' ||
        texto == '×' ||
        texto == '÷') {
      cor = Colors.orange;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _pressionar(texto),
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: cor == null ? null : Colors.white,
          ), // ElevatedButton.styleFrom
          child: Text(
            texto,
            style: const TextStyle(fontSize: 24),
          ), // Text
        ), // ElevatedButton
      ), // Padding
    ); // Expanded
  }
}
