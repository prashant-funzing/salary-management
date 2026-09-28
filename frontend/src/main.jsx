import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { api } from './api';
import { Login } from './components';
import './style.css';
function App() {
  const [user, setUser] = useState(undefined);
  const [error, setError] = useState('');
  useEffect(() => { api('/session').then(data => setUser(data.user)).catch(error => setError(error.message)); }, []);
  if (user === undefined) return <p>{error || 'Loading…'}</p>;
  if (!user) return <Login onLogin={setUser}/>;
  return <main><h1>HR workspace</h1><button onClick={async () => { await api('/session', {method: 'DELETE'}); setUser(null); }}>Sign out</button></main>;
}
createRoot(document.getElementById('root')).render(<App/>);
