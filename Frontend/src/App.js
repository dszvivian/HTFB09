import { useEffect, useState } from 'react';

// Components
import Navigation from './components/Navigation';
import Search from './components/Search';
import Home from './components/Home';



function App() {
  
  return (
    <div>
      <Navigation/>
      <Search />

      <h3>Student Loans</h3>

    </div>
  );
}

export default App;