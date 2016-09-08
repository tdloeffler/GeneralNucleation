!=======================================================================
      subroutine Simple_Partial_ConfigGen(nType, nIndx, nMol, rosenRatio_New, rosenRatio_Old, rejMove)
      use SimParameters
      use Coords
      use CoodinateFunctions
      use ForceField
      use Constants
!      use Rosenbluth_Functions_LJ_Q
      use EnergyPointers, only: Rosen_Mol_New, Rosen_Mol_Old
      use CBMC_Variables
      use CBMC_Utility
      implicit none

      integer, intent(in) :: nType, nMol, nIndx
      logical, intent(out) :: rejMove      
      real(dp), intent(out):: rosenRatio_New, rosenRatio_Old
      
      logical :: isIncluded(1:maxMol)
      logical :: overlap(1:maxRosenTrial)
      integer :: i, iRosen, nSel, nTargetMol
      integer :: Atm1, Atm2, Atm3, Atm4
      integer :: bendType, bondType, dihedType
      integer :: bendType2, bendType3
      real(dp) :: E_Trial(1:maxRosenTrial)      
      real(dp) :: grnd,rotang
      real(dp) :: c_term,s_term
      real(dp) :: x_shift,y_shift,z_shift
      real(dp) :: x_rid_cm, y_rid_cm,z_rid_cm
      real(dp) :: E_Max, ProbRosen(1:maxRosenTrial), rosenNorm
      real(dp) :: ranNum, sumInt
      real(dp) :: k_bond, r_eq, r, Prob
      real(dp) :: r1, r2, r3
      real(dp) :: k_bend, ang_eq, ang
      real(dp) :: ang1, ang2, dihed
      real(dp) :: x1, y1, z1, dx, dy, dz 
      type(SimpleAtomCoords) :: v1, v2, v3
      
      newMol%molType = nType      
      call Rosen_CreateSubset(nIndx, isIncluded)
      isIncluded(nIndx) = .false.
      E_Trial = 0d0
      rejMove = .false.      
      do iRosen = 1, nRosenTrials(nType)
     
         !Initialize the first atom coordinates to 0      
        rosenTrial(iRosen)%x = 0d0
        rosenTrial(iRosen)%y = 0d0
        rosenTrial(iRosen)%z = 0d0

         !Depending the number of atoms in the molecule, choose an appropriate algorithm
         !and regrow the atoms starting from atom 1. 
        select case(nAtoms(nType))
        case(1)
          continue
        case(2)
          Atm1 = pathArray(nType)%path(1, 1)
          Atm2 = pathArray(nType)%path(1, 2)        
          bondType = bondArray(nType,1)%bondType
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          rosenTrial(iRosen)%x(Atm2) = r * dx
          rosenTrial(iRosen)%y(Atm2) = r * dy
          rosenTrial(iRosen)%z(Atm2) = r * dz
        case(3)
          Atm1 = pathArray(nType)%path(1, 1)
          Atm2 = pathArray(nType)%path(1, 2)
          Atm3 = pathArray(nType)%path(1, 3)
          call FindBond(nType, Atm1, Atm2, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          v1%x = -r*dx
          v1%y = -r*dy
          v1%z = -r*dz
          rosenTrial(iRosen)%x(atm2) = r * dx
          rosenTrial(iRosen)%y(atm2) = r * dy
          rosenTrial(iRosen)%z(atm2) = r * dz
          call FindBond(nType, Atm2, Atm3, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          bendType = bendArray(nType,1)%bendType
!          k_bend = bendData(bendType)%k_eq
!          ang_eq = bendData(bendType)%ang_eq
!          call GenerateBendAngle(ang, k_bend, ang_eq, Prob)
          call GenerateBendAngle(ang, bendType, Prob)
          call Generate_UnitCone(v1, r, ang, v2)
          rosenTrial(iRosen)%x(atm3) = rosenTrial(iRosen)%x(atm2) + v2%x 
          rosenTrial(iRosen)%y(atm3) = rosenTrial(iRosen)%y(atm2) + v2%y
          rosenTrial(iRosen)%z(atm3) = rosenTrial(iRosen)%z(atm2) + v2%z
        case(4)
          Atm1 = pathArray(nType)%path(1, 1)
          Atm2 = pathArray(nType)%path(1, 2)
          Atm3 = pathArray(nType)%path(2, 1)
          Atm4 = pathArray(nType)%path(3, 1)
          call FindBond(nType, Atm1, Atm2, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r1, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          v1%x = -r1*dx
          v1%y = -r1*dy
          v1%z = -r1*dz
          rosenTrial(iRosen)%x(atm2) = r1 * dx
          rosenTrial(iRosen)%y(atm2) = r1 * dy
          rosenTrial(iRosen)%z(atm2) = r1 * dz
          call FindBond(nType, Atm2, Atm3, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r2, k_bond, r_eq, Prob)
          call FindBond(nType, Atm2, Atm4, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r3, k_bond, r_eq, Prob)
          call FindAngle(nType, Atm1, Atm2, Atm3, bendType)
          call FindAngle(nType, Atm1, Atm2, Atm4, bendType2)
          call FindAngle(nType, Atm3, Atm2, Atm4, bendType3)
          call FindSingleDihedral(nType, Atm2, dihedType)
          call GenerateTwoBranches(ang1, ang2, dihed, dihedType, bendType, bendType2, bendType3, Prob)
          call Generate_UnitPyramid(v1, r2, r3, ang1, ang2, dihed, v2, v3)
          rosenTrial(iRosen)%x(atm3) = rosenTrial(iRosen)%x(atm2) + v2%x 
          rosenTrial(iRosen)%y(atm3) = rosenTrial(iRosen)%y(atm2) + v2%y
          rosenTrial(iRosen)%z(atm3) = rosenTrial(iRosen)%z(atm2) + v2%z
          rosenTrial(iRosen)%x(atm4) = rosenTrial(iRosen)%x(atm2) + v3%x 
          rosenTrial(iRosen)%y(atm4) = rosenTrial(iRosen)%y(atm2) + v3%y
          rosenTrial(iRosen)%z(atm4) = rosenTrial(iRosen)%z(atm2) + v3%z
        case default
         stop "Error! Molecule has too many atoms for a simple regrowth"
        end select
        
        x1 = molArray(nType)%mol(nMol)%x(1) - rosenTrial(iRosen)%x(1)
        y1 = molArray(nType)%mol(nMol)%y(1) - rosenTrial(iRosen)%y(1)
        z1 = molArray(nType)%mol(nMol)%z(1) - rosenTrial(iRosen)%z(1)
        
        do i=1,nAtoms(nType)
          rosenTrial(iRosen)%x(i) = rosenTrial(iRosen)%x(i) + x1 
          rosenTrial(iRosen)%y(i) = rosenTrial(iRosen)%y(i) + y1 
          rosenTrial(iRosen)%z(i) = rosenTrial(iRosen)%z(i) + z1 
        enddo 

!        call Rosen_BoltzWeight_Molecule_New(iRosen, nType, isIncluded, E_Trial(iRosen), overlap(iRosen))
        call Rosen_Mol_New(iRosen, nType, isIncluded, E_Trial(iRosen), overlap(iRosen))
      enddo
      E_Max = minval(E_Trial)
      ProbRosen = 0d0
      do iRosen = 1, nRosenTrials(nType)
        ProbRosen(iRosen) = exp(-beta*(E_Trial(iRosen)-E_Max))         
      enddo

      if(all(ProbRosen .le. 0d0)) then
        rejMove = .true.
        return
      endif
      rosenNorm = sum(ProbRosen)
      
      ranNum = grnd() * rosenNorm
      sumInt = ProbRosen(1)
      nSel = 1
      do while(sumInt .lt. ranNum)
         nSel = nSel+1
         sumInt = sumInt + ProbRosen(nSel)
      enddo
      if(overlap(nSel) .eqv. .true.) then
        rejMove = .true.
        return
      endif
      rosenRatio_New = ProbRosen(nSel)/rosenNorm

!      Update the coordinates      
      newMol%x(1:nAtoms(nType)) = rosenTrial(nSel)%x(1:nAtoms(nType))
      newMol%y(1:nAtoms(nType)) = rosenTrial(nSel)%y(1:nAtoms(nType))
      newMol%z(1:nAtoms(nType)) = rosenTrial(nSel)%z(1:nAtoms(nType))
      


!      To simulate the reverse move, calculate the 
!      call Rosen_BoltzWeight_Molecule_Old(molArray(nType)%mol(nMol)%x(:), molArray(nType)%mol(nMol)%y(:), &
!                                 molArray(nType)%mol(nMol)%z(:), nType, isIncluded, E_Trial(1))   
      call Rosen_Mol_Old(molArray(nType)%mol(nMol)%x(:), molArray(nType)%mol(nMol)%y(:), &
                                 molArray(nType)%mol(nMol)%z(:), nType, isIncluded, E_Trial(1))  
      do iRosen = 2, nRosenTrials(nType)
     
!        Initialize the first atom coordinates to 0      
        rosenTrial(iRosen)%x = 0d0
        rosenTrial(iRosen)%y = 0d0
        rosenTrial(iRosen)%z = 0d0

!        Depending the molecule type, choose an appropriate algorithm
!        and regrow the atoms starting from atom 1. 
        select case(nAtoms(nType))
        case(1)
          continue
        case(2)
          Atm1 = pathArray(nType)%path(1, 1)
          Atm2 = pathArray(nType)%path(1, 2)        
          bondType = bondArray(nType,1)%bondType
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          rosenTrial(iRosen)%x(Atm2) = r * dx
          rosenTrial(iRosen)%y(Atm2) = r * dy
          rosenTrial(iRosen)%z(Atm2) = r * dz
        case(3)
          Atm1 = pathArray(nType)%path(1, 1)
          Atm2 = pathArray(nType)%path(1, 2)
          Atm3 = pathArray(nType)%path(1, 3)
          call FindBond(nType, Atm1, Atm2, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          v1%x = -r*dx
          v1%y = -r*dy
          v1%z = -r*dz
          rosenTrial(iRosen)%x(atm2) = r * dx
          rosenTrial(iRosen)%y(atm2) = r * dy
          rosenTrial(iRosen)%z(atm2) = r * dz
          call FindBond(nType, Atm2, Atm3, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          bendType = bendArray(nType,1)%bendType
!          k_bend = bendData(bendType)%k_eq
!          ang_eq = bendData(bendType)%ang_eq
!          call GenerateBendAngle(ang, k_bend, ang_eq, Prob)
          call GenerateBendAngle(ang, bendType, Prob)
          call Generate_UnitCone(v1, r, ang, v2)
          rosenTrial(iRosen)%x(atm3) = rosenTrial(iRosen)%x(atm2) + v2%x 
          rosenTrial(iRosen)%y(atm3) = rosenTrial(iRosen)%y(atm2) + v2%y
          rosenTrial(iRosen)%z(atm3) = rosenTrial(iRosen)%z(atm2) + v2%z
        case(4)
          Atm1 = pathArray(nType)%path(1, 1)
          Atm2 = pathArray(nType)%path(1, 2)
          Atm3 = pathArray(nType)%path(2, 1)
          Atm4 = pathArray(nType)%path(3, 1)
          call FindBond(nType, Atm1, Atm2, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r1, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          v1%x = -r1*dx
          v1%y = -r1*dy
          v1%z = -r1*dz
          rosenTrial(iRosen)%x(atm2) = r1 * dx
          rosenTrial(iRosen)%y(atm2) = r1 * dy
          rosenTrial(iRosen)%z(atm2) = r1 * dz
          call FindBond(nType, Atm2, Atm3, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r2, k_bond, r_eq, Prob)
          call FindBond(nType, Atm2, Atm4, bondType)
          k_bond = bondData(bondType)%k_eq
          r_eq = bondData(bondType)%r_eq
          call GenerateBondLength(r3, k_bond, r_eq, Prob)
          call FindAngle(nType, Atm1, Atm2, Atm3, bendType)
          call FindAngle(nType, Atm1, Atm2, Atm4, bendType2)
          call FindAngle(nType, Atm3, Atm2, Atm4, bendType3)
          call FindSingleDihedral(nType, Atm2, dihedType)
          call GenerateTwoBranches(ang1, ang2, dihed, dihedType, bendType, bendType2, bendType3, Prob)
          call Generate_UnitPyramid(v1, r2, r3, ang1, ang2, dihed, v2, v3)
          rosenTrial(iRosen)%x(atm3) = rosenTrial(iRosen)%x(atm2) + v2%x 
          rosenTrial(iRosen)%y(atm3) = rosenTrial(iRosen)%y(atm2) + v2%y
          rosenTrial(iRosen)%z(atm3) = rosenTrial(iRosen)%z(atm2) + v2%z
          rosenTrial(iRosen)%x(atm4) = rosenTrial(iRosen)%x(atm2) + v3%x 
          rosenTrial(iRosen)%y(atm4) = rosenTrial(iRosen)%y(atm2) + v3%y
          rosenTrial(iRosen)%z(atm4) = rosenTrial(iRosen)%z(atm2) + v3%z
        case default
         stop "Error! Molecule has too many atoms for a simple regrowth"
        end select
        
        x1 = molArray(nType)%mol(nMol)%x(1) - rosenTrial(iRosen)%x(1)
        y1 = molArray(nType)%mol(nMol)%y(1) - rosenTrial(iRosen)%y(1)
        z1 = molArray(nType)%mol(nMol)%z(1) - rosenTrial(iRosen)%z(1)
        
        do i=1,nAtoms(nType)
          rosenTrial(iRosen)%x(i) = rosenTrial(iRosen)%x(i) + x1 
          rosenTrial(iRosen)%y(i) = rosenTrial(iRosen)%y(i) + y1 
          rosenTrial(iRosen)%z(i) = rosenTrial(iRosen)%z(i) + z1 
        enddo 

!        call Rosen_BoltzWeight_Molecule_New(iRosen, nType, isIncluded, E_Trial(iRosen), overlap(iRosen))
        call Rosen_Mol_New(iRosen, nType, isIncluded, E_Trial(iRosen), overlap(iRosen))
      enddo
      E_Max = minval(E_Trial)
      ProbRosen = 0d0
      do iRosen = 1, nRosenTrials(nType)
        ProbRosen(iRosen) = exp(-beta*(E_Trial(iRosen)-E_Max))         
      enddo
      rosenNorm = sum(ProbRosen)
      rosenRatio_Old = ProbRosen(1)/rosenNorm

      
      end subroutine

!=======================================================================
      subroutine StraightChain_Partial_ConfigGen(nType, nMol, regrownIn, regrowDirection, startAtom, rosenRatio, rejMove)
      use SimParameters
      use Coords
      use CoodinateFunctions
      use ForceField
      use Constants
      use Rosenbluth_Functions_LJ_Q
      use CBMC_Variables
      use CBMC_Utility
      implicit none

      integer, intent(in) :: nType, nMol
      logical, intent(in) :: regrowDirection
      integer, intent(in) :: startAtom
      real(dp), intent(out):: rosenRatio
      logical, intent(out) :: rejMove
      logical, intent(in) :: regrownIn(1:maxAtoms)

      integer :: i, iRosen, iAtom, nSel, nIndx, nTargetMol
      integer :: Atm1, Atm2, Atm3, Atm4
      integer :: Incrmt
      integer :: bondType, bendType, torsType
      integer :: totalRegrown, curPos
      logical :: regrown(1:maxAtoms)
      logical :: isIncluded(1:maxMol)
      logical :: overlap(1:maxRosenTrial)

      real(dp) :: E_Trial(1:maxRosenTrial), E_Complete
      real(dp) :: grnd,rotang
      real(dp) :: ranNum, sumInt
      real(dp) :: k_bond, r_eq, r, Prob
      real(dp) :: k_bend, ang_eq, bend_angle, tors_angle
      real(dp) :: dx, dy, dz 
      type(SimpleAtomCoords) :: trialPos(1:maxRosenTrial)
      type(SimpleAtomCoords) :: v1, v2, v3
      
      do i = 1, maxAtoms
        regrown(i) = regrownIn(i)
      enddo

      if(regrowDirection) then
        Incrmt =  1
      else
        Incrmt = -1
      endif  
 
      nIndx = molArray(nType)%mol(nMol)%indx
      call Rosen_CreateSubset(nIndx, isIncluded)
      isIncluded(nIndx) = .false. 
      newMol%molType = nType 
      newMol%x = 0d0
      newMol%y = 0d0
      newMol%z = 0d0
      rejMove = .false.

!      For any atoms that are not chosen for regrowth, assign 
      totalRegrown = 0
      do i = 1, nAtoms(nType)
        if(regrown(i)) then
         newMol%x(i) = molArray(nType)%mol(nMol)%x(i)
         newMol%y(i) = molArray(nType)%mol(nMol)%y(i)
         newMol%z(i) = molArray(nType)%mol(nMol)%z(i)
         totalRegrown = totalRegrown + 1
        endif
      enddo
       
!      Having inserted the first atom, when we go to insert the second atom we must account for the fact that
!      the second atom must be inserted at the correct bond distance from the first atom.
      do i = 1, patharray(nType)%pathmax(1)
        if(patharray(nType)%path(1,i) .eq. startAtom) then
          curPos = i
        endif
      enddo

      rosenRatio = 1d0      
      if(totalRegrown .eq. 1) then
        if(curPos .eq. 1) then
          curPos = curPos + 1
        endif
        if(curPos .eq. patharray(nType)%pathmax(1)) then
          curPos = curPos - 1
        endif
        Atm2 = patharray(nType)%path(1,curPos)
        Atm1 = patharray(nType)%path(1,curPos-Incrmt)
!        call FindNextBondFromPath(nType, regrown, 1, Atm2, Atm1)
        call FindBond(nType,Atm1, Atm2, bondType)
        k_bond = bondData(bondType)%k_eq
        r_eq = bondData(bondType)%r_eq
        overlap = .false.
        do iRosen = 1, nRosenTrials(nType)
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          trialPos(iRosen)%x = r*dx + newMol%x(Atm1) 
          trialPos(iRosen)%y = r*dy + newMol%y(Atm1)
          trialPos(iRosen)%z = r*dz + newMol%z(Atm1)
          call Rosen_BoltzWeight_Atom_New(nType, Atm2, trialPos(iRosen), isIncluded,  E_Trial(iRosen), overlap(iRosen))
        enddo
        call ChooseRosenTrial(Atm2, nType, trialPos, regrown, E_Trial, overlap, rosenRatio, rejMove)  
        if(rejMove) then
          return
        endif
        regrown(Atm2) = .true.
        curPos = curPos + Incrmt
        totalRegrown = totalRegrown + 1
      endif

!       For the third atom we must begin to include the bending angle in choosing its trial positions. The first thing
!       we must consider is if the second regrown atom was a terminal atom or a linker atom. If it was a terminal atom 
!       then the bending angle must use the 1st atom as the central atom for the angle generation.  However if it was a link in the chain then the 2nd 
!       atom regrown should be used as the central atom.
      if(totalRegrown .eq. 2) then
        Atm3 = patharray(nType)%path(1,curPos)
        Atm2 = patharray(nType)%path(1,curPos - 1*Incrmt)
        Atm1 = patharray(nType)%path(1,curPos - 2*Incrmt)
        v1%x = newMol%x(Atm1) - newMol%x(Atm2)
        v1%y = newMol%y(Atm1) - newMol%y(Atm2)
        v1%z = newMol%z(Atm1) - newMol%z(Atm2)
        call FindBond(nType, Atm2, Atm3, bondType)
        k_bond = bondData(bondType)%k_eq
        r_eq = bondData(bondType)%r_eq
        call FindAngle(nType, Atm1, Atm2, Atm3, bendType)
!        k_bend = bendData(bendType)%k_eq
!        ang_eq = bendData(bendType)%ang_eq
        overlap = .false.
        do iRosen = 1, nRosenTrials(nType)
          call GenerateBondLength(r, k_bond, r_eq, Prob)
!          call GenerateBendAngle(bend_angle, k_bend, ang_eq, Prob)
          call GenerateBendAngle(bend_angle, bendType, Prob)
          call Generate_UnitCone(v1, r, bend_angle, v2)
          trialPos(iRosen)%x = v2%x + newMol%x(Atm2) 
          trialPos(iRosen)%y = v2%y + newMol%y(Atm2)
          trialPos(iRosen)%z = v2%z + newMol%z(Atm2)
          call Rosen_BoltzWeight_Atom_New(nType, Atm3, trialPos(iRosen), isIncluded,  E_Trial(iRosen), overlap(iRosen))
        enddo
        call ChooseRosenTrial(Atm3, nType, trialPos, regrown, E_Trial, overlap, rosenRatio, rejMove)
        if(rejMove) then
          return
        endif
        regrown(Atm3) = .true.
        curPos = curPos + Incrmt   
        totalRegrown = totalRegrown + 1
      endif


!      Now that three atoms have been regrown, all remaining atoms must take the torsional angles into account.
      do while(any(regrown .eqv. .false.))
        Atm4 = patharray(nType)%path(1,curPos           )
        Atm3 = patharray(nType)%path(1,curPos - 1*Incrmt)
        Atm2 = patharray(nType)%path(1,curPos - 2*Incrmt)
        Atm1 = patharray(nType)%path(1,curPos - 3*Incrmt)
!        call FindAtomsFromPath(nType, regrown, 1, Atm4, Atm1, Atm2, Atm3)
        call FindBond(nType, Atm3, Atm4, bondType)
        k_bond = bondData(bondType)%k_eq
        r_eq = bondData(bondType)%r_eq
        call FindAngle(nType, Atm2, Atm3, Atm4, bendType)
!        k_bend = bendData(bendType)%k_eq
!        ang_eq = bendData(bendType)%ang_eq
        call FindTorsion(nType, Atm1, Atm2, Atm3, Atm4, torsType)
        v1%x = newMol%x(Atm1) - newMol%x(Atm3)
        v1%y = newMol%y(Atm1) - newMol%y(Atm3)
        v1%z = newMol%z(Atm1) - newMol%z(Atm3)

        v2%x = newMol%x(Atm2) - newMol%x(Atm3)
        v2%y = newMol%y(Atm2) - newMol%y(Atm3)
        v2%z = newMol%z(Atm2) - newMol%z(Atm3)
        overlap = .false.
        do iRosen = 1, nRosenTrials(nType)
          call GenerateBondLength(r, k_bond, r_eq, Prob)
!          call GenerateBendAngle(bend_angle, k_bend, ang_eq, Prob)
          call GenerateBendAngle(bend_angle, bendType, Prob)
          call GenerateTorsAngle(tors_angle, torsType, Prob)
          call Generate_UnitTorsion(v1, v2, r, bend_angle, tors_angle, v3)
          trialPos(iRosen)%x = v3%x + newMol%x(Atm3) 
          trialPos(iRosen)%y = v3%y + newMol%y(Atm3)
          trialPos(iRosen)%z = v3%z + newMol%z(Atm3)
          call Rosen_BoltzWeight_Atom_New(nType, Atm4, trialPos(iRosen), isIncluded,  E_Trial(iRosen), overlap(iRosen))
        enddo
        call ChooseRosenTrial(Atm4, nType, trialPos, regrown, E_Trial, overlap, rosenRatio, rejMove)
        if(rejMove) then
          return
        endif
        regrown(Atm4) = .true.
        curPos = curPos + Incrmt   
        totalRegrown = totalRegrown + 1
      enddo

      end subroutine
!=======================================================================
      subroutine StraightChain_Partial_ConfigGen_Reverse(nType, nMol, regrownIn, regrowDirection, startAtom, rosenRatio)
      use SimParameters
      use Coords
      use CoodinateFunctions
      use ForceField
      use Constants
      use Rosenbluth_Functions_LJ_Q
      use CBMC_Variables
      use CBMC_Utility
      implicit none

      integer, intent(in) :: nType, nMol
      logical, intent(in) :: regrowDirection
      integer, intent(in) :: startAtom
      real(dp), intent(out):: rosenRatio
      logical, intent(in) :: regrownIn(1:maxAtoms)


      integer :: i, iRosen, iAtom, nSel, nIndx, nTargetMol
      integer :: Atm1, Atm2, Atm3, Atm4
      integer :: Incrmt
      integer :: bondType, bendType, torsType
      integer :: totalRegrown, curPos
      logical :: regrown(1:maxAtoms)
      logical :: isIncluded(1:maxMol)
      logical :: overlap

      real(dp) :: E_Trial(1:maxRosenTrial), E_Complete
      real(dp) :: grnd,rotang
      real(dp) :: ranNum, sumInt
      real(dp) :: E_Min, ProbRosen(1:maxRosenTrial), rosenNorm
      real(dp) :: k_bond, r_eq, r, Prob
      real(dp) :: k_bend, ang_eq, bend_angle, tors_angle
      real(dp) :: dx, dy, dz 
      type(SimpleAtomCoords) :: trialPos
      type(SimpleAtomCoords) :: v1, v2, v3
      
   
      regrown(1:maxAtoms) = regrownIn(1:maxAtoms)
      if(regrowDirection) then
        Incrmt =  1
      else
        Incrmt = -1
      endif  
 
      nIndx = molArray(nType)%mol(nMol)%indx
      call Rosen_CreateSubset(nIndx, isIncluded)
      isIncluded(nIndx) = .false. 
!      For any atoms that are not chosen for regrowth, assign 
      totalRegrown = 0
      do i = 1, nAtoms(nType)
        if(regrown(i)) then
          totalRegrown = totalRegrown + 1
        endif
      enddo
       
!      Having inserted the first atom, when we go to insert the second atom we must account for the fact that
!      the second atom must be inserted at the correct bond distance from the first atom.
      do i = 1, patharray(nType)%pathmax(1)
        if(patharray(nType)%path(1,i) .eq. startAtom) then
          curPos = i
        endif
      enddo

      rosenRatio = 1d0
      
      if(totalRegrown .eq. 1) then
        if(curPos .eq. 1) then
          curPos = curPos + 1
        endif
        if(curPos .eq. patharray(nType)%pathmax(1)) then
          curPos = curPos - 1
        endif
        Atm2 = patharray(nType)%path(1,curPos)
        Atm1 = patharray(nType)%path(1,curPos-Incrmt)
!        call FindNextBondFromPath(nType, regrown, 1, Atm2, Atm1)
        call FindBond(nType,Atm1, Atm2, bondType)
        k_bond = bondData(bondType)%k_eq
        r_eq = bondData(bondType)%r_eq
        call Rosen_BoltzWeight_Atom_Old(nType, nMol, Atm2, isIncluded,  E_Trial(1))
        do iRosen = 2, nRosenTrials(nType)
          call GenerateBondLength(r, k_bond, r_eq, Prob)
          call Generate_UnitSphere(dx, dy, dz)
          trialPos%x = r*dx + molArray(nType)%mol(nMol)%x(Atm1) 
          trialPos%y = r*dy + molArray(nType)%mol(nMol)%y(Atm1)
          trialPos%z = r*dz + molArray(nType)%mol(nMol)%z(Atm1)
          call Rosen_BoltzWeight_Atom_New(nType, Atm2, trialPos, isIncluded,  E_Trial(iRosen), overlap)
        enddo
        E_Min = minval(E_Trial)
        ProbRosen = 0d0
        do iRosen = 1, nRosenTrials(nType)
          ProbRosen(iRosen) = exp(-beta*(E_Trial(iRosen)-E_Min))         
        enddo
        rosenNorm = sum(ProbRosen)
        rosenRatio = rosenRatio*ProbRosen(1)/rosenNorm
        regrown(Atm2) = .true.
        curPos = curPos + Incrmt
        totalRegrown = totalRegrown + 1
      endif

!       For the third atom we must begin to include the bending angle in choosing its trial positions. The first thing
!       we must consider is if the second regrown atom was a terminal atom or a linker atom. If it was a terminal atom 
!       then the bending angle must use the 1st atom as the central atom for the angle generation.  However if it was a link in the chain then the 2nd 
!       atom regrown should be used as the central atom.
      if(totalRegrown .eq. 2) then
        Atm3 = patharray(nType)%path(1,curPos)
        Atm2 = patharray(nType)%path(1,curPos - 1*Incrmt)
        Atm1 = patharray(nType)%path(1,curPos - 2*Incrmt)
        v1%x = molArray(nType)%mol(nMol)%x(Atm1) - molArray(nType)%mol(nMol)%x(Atm2)
        v1%y = molArray(nType)%mol(nMol)%y(Atm1) - molArray(nType)%mol(nMol)%y(Atm2)
        v1%z = molArray(nType)%mol(nMol)%z(Atm1) - molArray(nType)%mol(nMol)%z(Atm2)
        call FindBond(nType, Atm2, Atm3, bondType)
        k_bond = bondData(bondType)%k_eq
        r_eq = bondData(bondType)%r_eq
        call FindAngle(nType, Atm1, Atm2, Atm3, bendType)
!        k_bend = bendData(bendType)%k_eq
!        ang_eq = bendData(bendType)%ang_eq
        call Rosen_BoltzWeight_Atom_Old(nType, nMol, Atm3, isIncluded,  E_Trial(1))
        do iRosen = 2, nRosenTrials(nType)
          call GenerateBondLength(r, k_bond, r_eq, Prob)
!          call GenerateBendAngle(bend_angle, k_bend, ang_eq, Prob)
          call GenerateBendAngle(bend_angle, bendType, Prob)
          call Generate_UnitCone(v1, r, bend_angle, v2)
          trialPos%x = v2%x + molArray(nType)%mol(nMol)%x(Atm2) 
          trialPos%y = v2%y + molArray(nType)%mol(nMol)%y(Atm2)
          trialPos%z = v2%z + molArray(nType)%mol(nMol)%z(Atm2)
          call Rosen_BoltzWeight_Atom_New(nType, Atm3, trialPos, isIncluded,  E_Trial(iRosen), overlap)
        enddo
        E_Min = minval(E_Trial)
        ProbRosen = 0d0
        do iRosen = 1, nRosenTrials(nType)
          ProbRosen(iRosen) = exp(-beta*(E_Trial(iRosen)-E_Min))         
        enddo
        rosenNorm = sum(ProbRosen)
        rosenRatio = rosenRatio*ProbRosen(1)/rosenNorm
        regrown(Atm3) = .true.
        curPos = curPos + Incrmt   
        totalRegrown = totalRegrown + 1
      endif


!      Now that three atoms have been regrown, all remaining atoms must take the torsional angles into account.
      do while(any(regrown .eqv. .false.))
        Atm4 = patharray(nType)%path(1,curPos           )
        Atm3 = patharray(nType)%path(1,curPos - 1*Incrmt)
        Atm2 = patharray(nType)%path(1,curPos - 2*Incrmt)
        Atm1 = patharray(nType)%path(1,curPos - 3*Incrmt)
        call FindAtomsFromPath(nType, regrown, 1, Atm4, Atm1, Atm2, Atm3)
        call FindBond(nType, Atm3, Atm4, bondType)
        k_bond = bondData(bondType)%k_eq
        r_eq = bondData(bondType)%r_eq
        call FindAngle(nType, Atm2, Atm3, Atm4, bendType)
!        k_bend = bendData(bendType)%k_eq
!        ang_eq = bendData(bendType)%ang_eq
        call FindTorsion(nType, Atm1, Atm2, Atm3, Atm4, torsType)
        v1%x = molArray(nType)%mol(nMol)%x(Atm1) - molArray(nType)%mol(nMol)%x(Atm3)
        v1%y = molArray(nType)%mol(nMol)%y(Atm1) - molArray(nType)%mol(nMol)%y(Atm3)
        v1%z = molArray(nType)%mol(nMol)%z(Atm1) - molArray(nType)%mol(nMol)%z(Atm3)

        v2%x = molArray(nType)%mol(nMol)%x(Atm2) - molArray(nType)%mol(nMol)%x(Atm3)
        v2%y = molArray(nType)%mol(nMol)%y(Atm2) - molArray(nType)%mol(nMol)%y(Atm3)
        v2%z = molArray(nType)%mol(nMol)%z(Atm2) - molArray(nType)%mol(nMol)%z(Atm3)
        call Rosen_BoltzWeight_Atom_Old(nType, nMol, Atm4, isIncluded,  E_Trial(1))
        do iRosen = 2, nRosenTrials(nType)
          call GenerateBondLength(r, k_bond, r_eq, Prob)
!          call GenerateBendAngle(bend_angle, k_bend, ang_eq, Prob)
          call GenerateBendAngle(bend_angle, bendType, Prob)
          call GenerateTorsAngle(tors_angle, torsType, Prob)
          call Generate_UnitTorsion(v1, v2, r, bend_angle, tors_angle, v3)
          trialPos%x = v3%x + molArray(nType)%mol(nMol)%x(Atm3) 
          trialPos%y = v3%y + molArray(nType)%mol(nMol)%y(Atm3)
          trialPos%z = v3%z + molArray(nType)%mol(nMol)%z(Atm3)
          call Rosen_BoltzWeight_Atom_New(nType, Atm4, trialPos, isIncluded,  E_Trial(iRosen), overlap)
        enddo
        E_Min = minval(E_Trial)
        ProbRosen = 0d0
        do iRosen = 1, nRosenTrials(nType)
          ProbRosen(iRosen) = exp(-beta*(E_Trial(iRosen)-E_Min))         
        enddo
        rosenNorm = sum(ProbRosen)
        rosenRatio = rosenRatio*ProbRosen(1)/rosenNorm
        regrown(Atm4) = .true.
        curPos = curPos + Incrmt   
        totalRegrown = totalRegrown + 1
      enddo

      end subroutine
