//import logo from '../assets/';  //import Logo Here

const Navigation = () => {

  
   return (
        <nav>
            <ul className='nav__links'>
                <li><a href="#">OPt1</a></li>
                <li><a href="#">Opt2</a></li>
                <li><a href="#">Opt3</a></li>
            </ul>

            <div className='nav__brand'>
                <img src='' alt="Logo Here" /> 
                <h1>Student Loans</h1>
            </div>

                <button
                    type="button"
                    className='nav__connect'
                >
                    Connect
                </button>
          
        </nav>
    );


}

export default Navigation;
