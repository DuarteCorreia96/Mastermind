from random import randint


# Gera código na forma int
def GenerateCode():

    return randint(0, sizeS)


# Dá decode de um inteiro para a forma [] * 4
def DecodeS(play):

    p = []

    k = 1
    for x in range(3, -1, -1):
        p.append(play // k % 6 + 1)
        k *= 6

    return p


# Descodifica a avaliação do valor inteiro para PB- para posterior impressão
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


# Veriifca se as jogadas estão em S
def CheckInS(plays, codeavals, playtocheck):

    for x in range(len(plays) - 1):
        if(codeavals[x] != HitCount(plays[x], playtocheck)):
            return False

    return True


# Retorna o numero de pretos e brancos
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
def GetNextPLay(plays, codeavals):

    mins = 99999999
    minplay = -1
    inS = False

    for play in range(sizeS):

        if play in plays:
            continue

        aval = [0] * 21

        for x in range(sizeS):
            if CheckInS(plays, codeavals, x):
                aval[HitCount(play, x)] += 1

        maxs = max(aval)
        if maxs > mins:
            continue

        playinS = CheckInS(plays, codeavals, play)
        if maxs < mins:

            if playinS:
                inS = True

            else:
                inS = False

            mins = maxs
            minplay = play
            continue

        # max(aval) == mins
        elif not inS and playinS:

            inS = True
            mins = maxs
            minplay = play

    return minplay


# Print jogada e avaliação
def PrintPLay(nplay, play, aval):

        playtoprint = ''.join(map(str, DecodeS(play)))
        avaltoprint = ''.join(map(str, DecodeAval(aval)))
        print("  " + str(nplay) + ": " + playtoprint + " | " + avaltoprint)


def main():

    nplay = 1
    plays = [7]
    code = GenerateCode()

    codetoprint = ''.join(map(str, DecodeS(code)))
    print("\n  Code: " + codetoprint + " \n")

    firstaval = HitCount(plays[0], code)
    codeavals = [firstaval]

    PrintPLay(nplay, plays[0], firstaval)

    # aval = 20 <=> aval = PPPP
    while codeavals[len(codeavals) - 1] != 20:

        nextplay = GetNextPLay(plays, codeavals)
        plays.append(nextplay)

        nextaval = HitCount(nextplay, code)
        codeavals.append(nextaval)

        nplay += 1
        PrintPLay(nplay, nextplay, nextaval)

    return 0


#Programa principal
ncores = 6
sizecode = 4
sizeS = ncores ** sizecode

main()
