from random import randint


# Gera código na forma int
def GenerateCode():

    return randint(0, sizeS)


# Dá decode de um inteiro para a forma [] * 4
# Pressupõe size do code = 4
def DecodeS(play):

    p = []

    k = 1
    for x in range(3, -1, -1):
        p.append(play // k % 6 + 1)
        k *= 6

    return p


# Descodifica a avaliação do valor inteiro para PB- para posterior impressão
# Pressupõe size do code = 4
def DecodeAval(aval):

    avalarr = []
    b = 0
    p = 0
    while (aval % 5) != 0:
        b += 1
        aval -= 1

    while aval != 0:
        p += 1
        aval -= 5

    for x in range(p):
        avalarr.append("P")

    for x in range(p, b + p):
        avalarr.append("B")

    for x in range(b + p, 4):
        avalarr.append("-")

    return avalarr


# Inicia S após a jogada e avaliação inicial
def CreateS(code, play):

    S = []

    # Avaliação do código com a jogada
    avalcode = HitCount(play, code)

    # Se os valores tiverem a mesma avaliação com a jogada
    #  teve com o código então podem ser o código
    for x in range(sizeS):
        if(avalcode == HitCount(play, x)):
            S.append(x)

    return S


# Veriifca se as jogadas estão em S
def TakefromS(S, code, play):

    x = 0

    # Avaliação do código com a jogada
    avalcode = HitCount(play, code)

    # Raciocinio conrário ao do CreateS
    while x <= len(S) - 1:
        if(avalcode != HitCount(play, S[x])):
            S.remove(S[x])

        x += 1

    return S


# Retorna o numero de pretos * 5 + brancos
# Pressupõe size do code = 4
def HitCount(code, test):

    p = 0
    b = 0

    code = DecodeS(code)
    test = DecodeS(test)

    for x in range(4):
        if code[x] == test[x]:

            p += 1
            code[x] = 0
            test[x] = 0

    for x in range(4):

        if test[x] == 0:
            continue

        for y in range(4):

            if test[x] == code[y]:

                b += 1
                code[y] = 0
                test[x] = 0
                break

    return 5 * p + b


# Retorna a próxima jogada
def GetNextPLay(S, plays, code):

    mins = 99999999
    minplay = -1

    for guess in range(sizeS):

        inS = False

        # Passa as jogadas já feitas
        if guess in plays:
            continue

        # Cria um array com as avals da play com os elementos de S
        # Apenas algumas posições são usadas:
        # 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 15, 16, 20
        # Não usadas: 0, 9, 13, 17, 18, 19
        #   tem-se de manter inferiores ao valor de inicialização do array
        #   mas podem ser usadas se necessário
        avals = [0] * 21
        for x in range(len(S) - 1):
            avals[HitCount(guess, S[x])] += 1

        # Avaliação mais recorrente, i.e., o pior caso da play a avaliar
        maxs = max(avals)

        # Verificar dos piores casos o que elimina mais possibilidades (minmax)
        if maxs > mins:
            continue

        elif maxs < mins:

            inS = True if guess in S else False

            mins = maxs
            minplay = guess
            continue

        # if max(aval) == mins
        elif not inS and guess in S:

            inS = True
            mins = maxs
            minplay = guess

    return minplay


# Print jogada e avaliação
def PrintPLay(nplay, play, aval):

        playtoprint = ''.join(map(str, DecodeS(play)))
        avaltoprint = ''.join(map(str, DecodeAval(aval)))
        print("  " + str(nplay) + ": " + playtoprint + " | " + avaltoprint)


def main():

    plays = [7]
    nplay = 1
    code = GenerateCode()
    S = CreateS(code, plays[0])

    # Impressões iniciais
    codetoprint = ''.join(map(str, DecodeS(code)))
    print("\n  Code: " + codetoprint + " \n")

    aval = HitCount(plays[0], code)
    PrintPLay(nplay, plays[0], aval)

    # aval = 20 <=> aval = PPPP
    # Enquanto não se descobrir o código procurar nova jogada
    while aval != 20:

        nextplay = GetNextPLay(S, plays, code)
        S = TakefromS(S, code, nextplay)

        plays.append(nextplay)

        # Impressão da Jogada
        aval = HitCount(nextplay, code)

        nplay += 1
        PrintPLay(nplay, nextplay, aval)

    return 0


#Programa principal
ncores = 6
sizecode = 4
sizeS = ncores ** sizecode

main()
