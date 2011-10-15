# By Anya Kuznetsova


import numpy
import MySQLdb
import sys


def poly_search (label, keywordID=None) :
    db = MySQLdb.connect("128.97.46.193", "anya", "rips", "vhf_report")
    cursor=db.cursor()

    if keywordID is None:
        q = 'SELECT KeywordID FROM GeoKeyword WHERE Label LIKE "%{}%"'.format(label)
        cursor.execute(q)
        keywordID = cursor.fetchone()[0]

    firstQ = "select Gens from AdjList2_norm where KeywordID = %s" % keywordID
    cursor.execute(firstQ)

    Gens = cursor.fetchone()
    Gens = map(int, Gens[0].split())

    firstQ = "select Freq from AdjList2_norm where KeywordID = %s" % keywordID
    cursor.execute(firstQ)

    normFreq = cursor.fetchone()
    normFreq = map(float, normFreq[0].split())


    firstQ = "select Freq from AdjList2 where KeywordID = %s" % keywordID
    cursor.execute(firstQ)

    Freq = cursor.fetchone()
    Freq = map(float, Freq[0].split())

    Q=  "set @point = (select LonLat from Location where KeywordID = %s)" % keywordID
    cursor.execute(Q)

    Q = "select POLYGONS.KeywordID from POLYGONS where MBRContains(Ring, @point)=1"
    cursor.execute(Q)
    Polygons =[]
    Pols = cursor.fetchall()

    for pol in Pols :
        Polygons.append(pol[0])

    #=============================================================================
    #===============================LIST 1========================================
    #=============================================================================

    # sortedPolyGens gives you a list of keywords that are COMMON to the area AND happen in this geo-keyword - sorted by frequency (descending)
    # sortedPolyFreq gives you a list of keyword frequencies corresponding to sortedPolyGens

	CommonInd = [];
	sortedPolyFreq=[];
	sortedPolyGens=[];
	
	for x in Polygons :
		if x in Gens :
			CommonInd.append(Gens.index(x))
			sortedPolyGens.append(x)
			sortedPolyFreq.append(Freq[Gens.index(x)])
			
	if len(CommonInd)==0 :
		sortedPolyGens=list();
		uniqueG=list();
	else :
		Poly = zip(sortedPolyGens, sortedPolyFreq)
		Poly.sort(key=lambda x:x[1], reverse=True)

		sortedPolyGens, sortedPolyFreq = zip(*Poly)


		for x in Polygons :
			if x in Gens :
				Freq.remove(Freq[Gens.index(x)])
				normFreq.remove(normFreq[Gens.index(x)])
				Gens.remove(x)
    #=============================================================================
    #===============================LIST 2========================================
    #=============================================================================

    # uniqueG gives you a list of unique general keywords to the geo-keyword (sorted by frequency - descending)
    # uniqueF gives you a list of frequencies that correspond to the geo-keyword

   		uniqueG = [];
		uniqueF=[];


		GF = zip(Gens, Freq, normFreq)
		for row in GF :
			if row[2]==1 :
				uniqueG.append(row[0])
				uniqueF.append(row[1])

		
		if len(uniqueG)==0 :
			uniqueG=list();
			
		else :
			
			uniqueGF = zip(uniqueG, uniqueF)
			uniqueGF.sort(key=lambda x: x[1], reverse=True)

			uniqueG, uniqueF=zip(*uniqueGF)



    #=============================================================================
    #===============================LIST 3========================================
    #=============================================================================

    # NotUniqueNotCommon fives you a list of general keywords that are not common to the area and are not unique - sorted by frequency (descending)
    # F are the corresponding absolute frequencies


    GFF=zip(Gens,normFreq, Freq)
    GFF.sort(key =lambda x: x[2], reverse=True)

    NotUniqueNotCommon=[];
    F=[];

    for x in GFF :
        NotUniqueNotCommon.append(x[0])
        F.append(x[2])
    
    def labels(keywordID) :
        A=[];
        for IDs in keywordID :
            query="select Label from AllKeywords where KeywordID = %s" % IDs
            cursor.execute(query)
            B=cursor.fetchone()
            A.append(B[0])
        return A
    
    return [labels(sortedPolyGens), labels(uniqueG), labels(NotUniqueNotCommon)]
