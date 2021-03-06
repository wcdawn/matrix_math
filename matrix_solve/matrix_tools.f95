module matrixtools
IMPLICIT NONE

contains
subroutine matrixwrite(row,col,mat)
	IMPLICIT NONE
	integer, intent(in)  :: row, col
	integer              :: r, c
	real(8), intent(in)  :: mat(:,:)
	
	101 format(a)       ! plain text descriptor
	102 format(e12.6,x) ! exponential, length = 12, decimal = 6, follow w/ space
	
	do r = 1, row
		write(*,101,advance= 'no') '[ '
		do c = 1, col
			write(*,102,advance = 'no') mat(r,c)
		enddo
		write(*,101) ']'
	enddo
	write(*,101) ! blank line
	
endsubroutine matrixwrite

subroutine vectorwrite(row,vect)
	IMPLICIT NONE
	integer,intent(in) :: row
	integer :: i
	real(8),dimension(:),intent(in) :: vect
	
	103 format(a,e12.6,a)

	do i = 1,row
		write(*,103) '[ ', vect(i), ' ]'
	enddo
	
	write(*,*)
endsubroutine vectorwrite

subroutine matrixmul(row1,col1,mat1,row2,col2,mat2,rowans,colans,ansmat)
	IMPLICIT NONE
	integer, intent(in)  :: row1, col1, row2, col2
	integer              :: dis1, dis2, sim, i, j, k
	integer, intent(out) :: rowans, colans
	real(8), intent(in),  dimension(:,:)              :: mat1, mat2
	real(8), intent(out), dimension(:,:), allocatable :: ansmat
	
	101 format(a) ! plain text descriptor
	
	! check if matrix multiplication is allowed
	if (col1 .eq. row2) then
		sim = col1
		dis1 = row1
		dis2 = col2
	elseif (row1 .eq. col2) then
		write(*,101) 'I think you want mat2 * mat1'
		write(*,101) 'I cant do that right now'
		write(*,101) 'Switch mat1 & mat2 in input.'
		stop 'END OF PROGRAM'
	else
		stop('matrix multiplication not possible based on dimensions')
	endif
	
	allocate(ansmat(dis1,dis2))
	rowans = dis1
	colans = dis2
	
	do i = 1, dis1
		do j = 1, dis2
			ansmat(i,j) = 0.0d0
			do k = 1, sim
				! debug write
				! write(*,'(3e15.6,3i3)') mat1(i,k), mat2(k,i), (mat1(i,k) * mat2(k,i)), i, j, k
				ansmat(i,j) = ansmat(i,j) + (mat1(i,k) * mat2(k,j))
			enddo
		enddo
	enddo
endsubroutine matrixmul

subroutine matrixdecompose(row,col,mat,lower,upper)
	IMPLICIT NONE
	integer,intent(in) :: row, col
	integer :: ansrow, anscol
	integer :: i, j, k, w
	real(8),dimension(:,:),intent(in) :: mat
	real(8),dimension(:,:),intent(out),allocatable :: lower, upper
	real(8),dimension(:,:),allocatable :: ansmat
	real(8) :: asum, bsum
	
	101 format(a) ! plain text descriptor
	
	! Doolittle Algorithm
	! See wiki PDF
	
	if (row .ne. col) stop('LU decomposition is only defined for square matricies')
	allocate(lower(row,col),upper(row,col))
	lower(:,:) = 0.0d0
	upper(:,:) = 0.0d0
	do i = 1,row
		lower(i,i) = 1.0d0
	enddo
	
	do i = 1,row
		do j = i,row
			asum = 0.0d0
			do w = 1,(i - 1)
				asum = asum + lower(i,w) * upper(w,j)
			enddo
			upper(i,j) = mat(i,j) - asum
		enddo
		do k = 1,col
			bsum = 0.0d0
			do w = 1,(i - 1)
				bsum = bsum + lower(k,w) * upper(w,i)
			enddo
			lower(k,i) = (mat(k,i) - bsum) / upper(i,i)
		enddo
	enddo
	
	! Multiply L * U to make sure it worked
	! TO-DO: Remove this later
	! call matrixmul(row,col,lower,row,col,upper,ansrow,anscol,ansmat)
	! do i = 1,col
		! do j = 1,row
			! if (ansmat(i,j) .ne. mat(i,j)) then
				! write(*,'(2i3)') i,j
				! stop('decomposition didnt work')
			! endif
		! enddo
	! enddo
	! write(*,101) 'decomposition successful'
	! write(*,*)
	
endsubroutine matrixdecompose

subroutine matrixdet(row,col,mat,det_mat)
	IMPLICIT NONE
	integer,intent(in) :: row, col
	integer :: i
	real(8),dimension(:,:),intent(in) :: mat
	real(8),intent(out) :: det_mat
	real(8),dimension(:,:),allocatable :: lower, upper
	
	if (row .ne. col) stop('determinant only defined for square matricies')
	
	! First, decompose the matrix
	call matrixdecompose(row,col,mat,lower,upper)
	! determinant of a triangular matrix is the multiplication of the "angle"
	! det_lower = 1.0d0 ! definition from Doolittle algorithm
	det_mat = 1.0d0
	do i = 1,row
		det_mat = det_mat * upper(i,i)
	enddo

endsubroutine matrixdet

subroutine matrixsolve(row_coeff,col_coeff,coeff,row_ans,ans,sol)
	IMPLICIT NONE
	integer,intent(in) :: row_coeff, col_coeff, row_ans
	integer :: i, j
	real(8),dimension(:,:),intent(in) :: coeff
	real(8),dimension(:),intent(in) :: ans
	real(8),dimension(:),intent(out),allocatable :: sol
	real(8),dimension(:),allocatable :: y
	real(8) :: lower_sum, upper_sum
	real(8),dimension(:,:),allocatable :: lower, upper
	
	if (col_coeff .ne. row_ans) stop('not sure that is a linear system...')
	allocate(sol(row_coeff),y(row_coeff))
	call matrixdecompose(row_coeff,col_coeff,coeff,lower,upper)
	
	! forward subtitution (lower matrix)
	do i = 1,row_coeff
		lower_sum = 0.0d0
		do j = 1,(i - 1)
			lower_sum = lower_sum + (lower(i,j) * y(j))
		enddo
		y(i) = (ans(i) - lower_sum) / lower(i,i)
	enddo
	
	! backward subtitution (upper matrix)
	do i = row_coeff,1,-1
		upper_sum = 0.0d0
		do j = (i + 1),row_coeff
			upper_sum = upper_sum + upper(i,j) * sol(j)
		enddo
		sol(i) = (y(i) - upper_sum) / upper(i,i)
	enddo

endsubroutine matrixsolve

subroutine matrixread(unit_num,fname,row,col,mat)
	IMPLICIT NONE
	integer,intent(in) :: unit_num
	integer,intent(out) :: row,col
	integer :: ios,i
	real(8),intent(out),dimension(:,:),allocatable :: mat
	character(80),intent(in) :: fname
	
	! matrix file must have (row,col) in first line
	
	open(unit = unit_num, file = fname, status = 'old', action = 'read', iostat = ios)
	if (ios .ne. 0) then
		write(*,'(a,i3,a,a)') 'error opening unit', unit_num, ' -- ', fname
		stop('END PROGRAM')
	endif
	
	read(unit_num,*) row,col
	allocate(mat(row,col))
	do i = 1,row
		read(unit_num,*) mat(i,:)
	enddo
endsubroutine matrixread

subroutine matrixinv(row,col,mat,invmat)
	IMPLICIT NONE
	integer,intent(in) :: row,col
	integer :: i
	real(8),dimension(:,:),intent(in) :: mat
	real(8),dimension(:,:),intent(out),allocatable :: invmat
	real(8),dimension(:),allocatable :: invcol, identitycol
	real(8),dimension(:,:),allocatable :: identity
	real(8) :: det_mat, tol
	
	! NEVER EVER USE AN INVERT TO PERFORM A SOLVE!
	! THE INVERSION CALLS THE SOLVE SUBROUTINE N TIMES!
	
	101 format(a) ! plain text descriptor
	
	tol = 1.0d-2
	
	if (row .ne. col) stop ('inversion only for square matricies')
	
	! IEEE-FPE floating point error
	call matrixdet(row,col,mat,det_mat)
	allocate(invmat(row,col),identity(row,col))
	allocate(invcol(row),identitycol(row))
	invmat(:,:) = 0.0d0
	identity(:,:) = 0.0d0
	do i = 1,row
		identity(i,i) = 1.0d0
	enddo
		
	if ((det_mat .lt. tol) .and. (det_mat .gt. ((-1) * tol))) then
		write(*,101) 'matrix is singular (det = 0)'
		write(*,101) 'singular matricies are not invertable'
		stop('END PROGRAM')
	endif
	
	do i = 1,row
		invcol(:) = 0.0d0
		identitycol(:) = identity(:,i)
	
		call matrixsolve(row,col,mat,row,identitycol,invcol)
		
		invmat(:,i) = invcol(:)
	enddo
	
endsubroutine matrixinv
	
	
endmodule matrixtools