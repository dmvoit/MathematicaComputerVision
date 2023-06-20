(* Mathematica Package *)

BeginPackage["ComputerVision`Camera`",{"ComputerVision`Utils`","ComputerVision`Homographies`"}]

CameraMatrixFromCorrespondences::usage = "CameraMatrixFromCorrespondences[corr] gives the camera matrix for >=6 {world,pixel} correspondences (homogeneous coordinates) using a DLT method.";

CameraDecompose::usage = "DecomposeCamera[P] decomposes the camera into {K,R,t} such that P = K.R.[I | -t].";

DrawCamera::usage = "DrawCamera[P] gives a 3D object showing the camera orientation. To be used inside a Graphics3D environment. It uses the img for its dimensions.
DrawCamera[P,size] does the same with a given size.
DrawCamera[P,size,img] let's you specify an image used to find correct the width and height of the screen.";

Begin["`Private`"] (* Begin Private Context *) 

CameraMatrixFromCorrespondences[corr_] :=
	Module[{world, image, T, U, A, P,corr2},
		(* Normalize the points. *)
		world = Transpose[corr][[1]];
		image = Transpose[corr][[2]];
		{image,T} = NormalizePoints[image];
		{world,U} = NormalizePoints3D[world];
		corr2=Transpose[{world,image}];
		(* Find P for the normalized points. *)
		A = Flatten[
			{
				{0,0,0,0, -#[[2,3]]#[[1,1]],-#[[2,3]]#[[1,2]],-#[[2,3]]#[[1,3]],-#[[2,3]]#[[1,4]], #[[2,2]]#[[1,1]],#[[2,2]]#[[1,2]],#[[2,2]]#[[1,3]],#[[2,2]]#[[1,4]]},
				{#[[2,3]]#[[1,1]],#[[2,3]]#[[1,2]],#[[2,3]]#[[1,3]],#[[2,3]]#[[1,4]], 0,0,0,0, -#[[2,1]]#[[1,1]],-#[[2,1]]#[[1,2]],-#[[2,1]]#[[1,3]],-#[[2,1]]#[[1,4]]}
			}&/@corr2
		,1];
		P = Partition[SingularValueDecomposition[A][[3,All,-1]],4];
		
		(* Denormalize and return. *)
		Inverse[T].P.U
	];

CameraDecompose[P_] :=
	Module[{M,K,R,t,D},
		(* Define H as the first three columns of P. *)
		M = P[[All,1;;3]];
		(* K and R follow from an RQ decomposition. *)
		{K,R} = RQ[M];
		(* Make sure K[[3,3]] is 1. *)
		K = K/K[[3,3]];
		(* Make sure the f-components of K are positive, if not,
			change K and R *)
		If[K[[1,1]]<0,
			D = DiagonalMatrix[{-1,-1,1}];
			K = K.D;
			R = D.R;
		];
		(* Calculate t. *)
		t = NullSpace[P][[1]];
		(* Return values found. *)
		{K,R,t}
	];

DrawCamera[P_, size_ : 1, img_ : Null] :=
	Module[{K,R,t,f,Rinv,pts,w,h,px,py,det},
		(* Decompose the camera to get all parameters. *)
		{K,R,t} = CameraDecompose[P];
		(* Take the average value for f. *)
		f = (K[[1,1]]+K[[2,2]])/2;
		(* Convert t to non-homogeneous. *)
		t = Nc[t];
		(* Calculate the inverse rotation matrix. *)
		Rinv = Inverse[R];
		(* The displayed principal point distance is 1 x the sign of f. *)
		(* Other values *)
		px = K[[1,3]];
		py = K[[2,3]];
		(* The determinant of M is used to determine axis direction *)
		det = Det[P[[All,1;;3]]];
		(* Define the points and transform them. *)
		pts = size*{
			{0, 0, 0},
			{-px / f, -py / f, 1},
			{-px / f, py / f, 1},
			{ px / f, py / f, 1},
			{ px / f, -py / f, 1},
			{Sign[det], 0, 0},
			{0, Sign[det], 0}
		};
		pts = (Rinv.# + t) & /@ pts;
		(* Return the graphics primitives. *)
		{
			 PointSize[Large], Point[pts[[1]]],
			 Thick,
			 Red, Arrow[pts[[{1, 6}]]],
			 Green, Arrow[pts[[{1, 7}]]],
			 Gray, Opacity[.2],
			 Pyramid[pts[[2;;5]]//Append[pts[[1]]]]
		 }
	];

End[] (* End Private Context *)

EndPackage[]